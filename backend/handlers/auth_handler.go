package handlers

import (
	"comparebuddy-backend/config"
	"comparebuddy-backend/models"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"

	"github.com/gofiber/fiber/v2"
	"golang.org/x/crypto/bcrypt"
)

type RegisterRequest struct {
	Username    string `json:"username"`
	Email       string `json:"email"`
	Password    string `json:"password"`
	DisplayName string `json:"display_name"`
}

type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type GoogleLoginRequest struct {
	IDToken string `json:"id_token"`
}

func Register(c *fiber.Ctx) error {
	var req RegisterRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	req.Username = strings.TrimSpace(req.Username)
	req.Email = strings.TrimSpace(req.Email)
	req.DisplayName = strings.TrimSpace(req.DisplayName)

	if req.Username == "" || req.Password == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Username and password are required"})
	}

	if len(req.Password) < 6 {
		return c.Status(400).JSON(fiber.Map{"error": "Password must be at least 6 characters"})
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to hash password"})
	}

	displayName := req.DisplayName
	if displayName == "" {
		displayName = req.Username
	}

	result, err := config.DB.Exec(
		"INSERT INTO users (username, email, password_hash, display_name) VALUES (?, ?, ?, ?)",
		req.Username, req.Email, string(hash), displayName,
	)
	if err != nil {
		if strings.Contains(err.Error(), "Duplicate entry") {
			if strings.Contains(err.Error(), "username") {
				return c.Status(409).JSON(fiber.Map{"error": "Username already exists"})
			}
			if strings.Contains(err.Error(), "email") {
				return c.Status(409).JSON(fiber.Map{"error": "Email already exists"})
			}
			return c.Status(409).JSON(fiber.Map{"error": "User already exists"})
		}
		return c.Status(500).JSON(fiber.Map{"error": "Failed to create user"})
	}

	id, _ := result.LastInsertId()

	user := models.User{
		ID:          int(id),
		Username:    req.Username,
		Email:       req.Email,
		DisplayName: displayName,
	}

	return c.Status(201).JSON(fiber.Map{
		"message": "User registered successfully",
		"user":    user,
	})
}

func Login(c *fiber.Ctx) error {
	var req LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	req.Username = strings.TrimSpace(req.Username)

	if req.Username == "" || req.Password == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Username and password are required"})
	}

	var user models.User
	err := config.DB.QueryRow(
		"SELECT id, username, email, password_hash, display_name, COALESCE(avatar_url, '') FROM users WHERE username = ?",
		req.Username,
	).Scan(&user.ID, &user.Username, &user.Email, &user.PasswordHash, &user.DisplayName, &user.AvatarURL)

	if err == sql.ErrNoRows {
		return c.Status(401).JSON(fiber.Map{"error": "Invalid username or password"})
	}
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to query user"})
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		return c.Status(401).JSON(fiber.Map{"error": "Invalid username or password"})
	}

	return c.JSON(fiber.Map{
		"message": "Login successful",
		"user":    user,
	})
}

func GoogleLogin(c *fiber.Ctx) error {
	var req GoogleLoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	if req.IDToken == "" {
		return c.Status(400).JSON(fiber.Map{"error": "ID token is required"})
	}

	// Verify Google ID token
	googleUser, err := verifyGoogleToken(req.IDToken)
	if err != nil {
		return c.Status(401).JSON(fiber.Map{"error": "Invalid Google token"})
	}

	// Check if user exists by google_id
	var user models.User
	err = config.DB.QueryRow(
		"SELECT id, username, email, display_name, google_id, COALESCE(avatar_url, '') FROM users WHERE google_id = ?",
		googleUser.GoogleID,
	).Scan(&user.ID, &user.Username, &user.Email, &user.DisplayName, &user.GoogleID, &user.AvatarURL)

	if err == sql.ErrNoRows {
		// Create new user from Google info
		result, insertErr := config.DB.Exec(
			"INSERT INTO users (username, email, display_name, google_id, avatar_url) VALUES (?, ?, ?, ?, ?)",
			googleUser.Email, googleUser.Email, googleUser.Name, googleUser.GoogleID, googleUser.Picture,
		)
		if insertErr != nil {
			return c.Status(500).JSON(fiber.Map{"error": "Failed to create user"})
		}

		id, _ := result.LastInsertId()
		user = models.User{
			ID:          int(id),
			Username:    googleUser.Email,
			Email:       googleUser.Email,
			DisplayName: googleUser.Name,
			GoogleID:    googleUser.GoogleID,
			AvatarURL:   googleUser.Picture,
		}
	} else if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to query user"})
	}

	return c.JSON(fiber.Map{
		"message": "Login successful",
		"user":    user,
	})
}

type googleTokenInfo struct {
	GoogleID string `json:"sub"`
	Email    string `json:"email"`
	Name     string `json:"name"`
	Picture  string `json:"picture"`
}

func verifyGoogleToken(idToken string) (*googleTokenInfo, error) {
	resp, err := http.Get("https://oauth2.googleapis.com/tokeninfo?id_token=" + idToken)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("invalid token")
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var info googleTokenInfo
	if err := json.Unmarshal(body, &info); err != nil {
		return nil, err
	}

	return &info, nil
}
