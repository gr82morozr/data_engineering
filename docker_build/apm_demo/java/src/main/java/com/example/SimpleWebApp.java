package com.example;

import com.google.gson.Gson;
import spark.ResponseTransformer;

import static spark.Spark.*;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Arrays; 
import java.util.concurrent.ThreadLocalRandom;

public class SimpleWebApp {

    private static final String DB_CONNECTION = "jdbc:sqlite:employee.db";
    private static final Gson gson = new Gson();
    private static final Random random = new Random();
    private static final List<String> skills = Arrays.asList("Java", "Python", "JavaScript", "C++", "Elastic", "Linux");

    public static void main(String[] args) {
        // Set the port for Spark
        port(8080);

        // Serve static files from the 'public' directory under 'src/main/resources'
        staticFiles.location("/public");

        // Initialize database and populate with sample data
        
        initDatabase();
        populateSampleData();

        // Set up routes
        get("/", (req, res) -> "index.html");

        post("/add", (req, res) -> {
            String name = req.queryParams("name");
            String gender = req.queryParams("gender");
            String position = req.queryParams("position");
            String dob = req.queryParams("dob");
            String skillSet = req.queryParams("skillSet");
            addEmployee(name, gender, position, dob, skillSet);
            return "Employee added successfully";
        });

        post("/remove", (req, res) -> {
            int id = Integer.parseInt(req.queryParams("id"));
            removeEmployee(id);
            return "Employee removed successfully";
        });

        get("/employees", (req, res) -> {
            res.type("application/json");
            return queryEmployees();
        }, gson::toJson);
    }

    private static void initDatabase() {
        try (Connection conn = DriverManager.getConnection(DB_CONNECTION);
             Statement stmt = conn.createStatement()) {
            // Create table if not exists
            stmt.execute("DROP TABLE IF EXISTS employees");
            stmt.execute("CREATE TABLE IF NOT EXISTS employees (" +
                         "id INTEGER PRIMARY KEY AUTOINCREMENT," +
                         "name TEXT," +
                         "gender TEXT," +
                         "position TEXT," +
                         "dob DATE," +
                         "skillSet TEXT)");
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    private static void randomDelay() {
        try {
            // Random delay between 1 to 10 milliseconds
            int delay = ThreadLocalRandom.current().nextInt(1, 11);
            Thread.sleep(delay);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Thread was interrupted", e);
        }
    }

    private static void populateSampleData() {
        // Define possible genders
        List<String> genders = Arrays.asList("M", "F");

        // Add sample employees
        for (int i = 1; i <= 10; i++) {
            String gender = genders.get(random.nextInt(genders.size()));
            LocalDate dob = getRandomDob();
            String skillSet = skills.get(random.nextInt(skills.size()));

            addEmployee("Employee" + i, gender, "Position" + i, dob.toString(), skillSet);
        }
    }

    private static LocalDate getRandomDob() {
        int minDay = (int) LocalDate.of(1960, 1, 1).toEpochDay();
        int maxDay = (int) LocalDate.of(2000, 1, 1).toEpochDay();
        long randomDay = minDay + random.nextInt(maxDay - minDay);

        return LocalDate.ofEpochDay(randomDay);
    }

    private static void removeEmployee(int id) {
        randomDelay();
        String sql = "DELETE FROM employees WHERE id = ?";
        try (Connection conn = DriverManager.getConnection(DB_CONNECTION);
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, id);
            pstmt.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    private static void addEmployee(String name, String gender, String position, String dob, String skillSet) {
        randomDelay();
        String sql = "INSERT INTO employees (name, gender, position, dob, skillSet) VALUES (?, ?, ?, ?, ?)";
        try (Connection conn = DriverManager.getConnection(DB_CONNECTION);
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, name);
            pstmt.setString(2, gender);
            pstmt.setString(3, position);
            pstmt.setDate(4, Date.valueOf(dob));
            pstmt.setString(5, skillSet);
            pstmt.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    private static List<Employee> queryEmployees() {
        randomDelay();
        List<Employee> employees = new ArrayList<>();
        try (Connection conn = DriverManager.getConnection(DB_CONNECTION);
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT * FROM employees")) {

            while (rs.next()) {
                Employee employee = new Employee(
                        rs.getInt("id"),
                        rs.getString("name"),
                        rs.getString("gender"),
                        rs.getString("position"),
                        rs.getDate("dob"),
                        rs.getString("skillSet")
                );
                employees.add(employee);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return employees;
    }

    // Define an Employee class within SimpleWebApp for simplicity
    private static class Employee {
        int id;
        String name;
        String gender;
        String position;
        Date dob;
        String skillSet;

        Employee(int id, String name, String gender, String position, Date dob, String skillSet) {
            this.id = id;
            this.name = name;
            this.gender = gender;
            this.position = position;
            this.dob = dob;
            this.skillSet = skillSet;
        }
    }

    // A utility method to convert objects to JSON using Gson
    private static String toJson(Object object) {
        return gson.toJson(object);
    }
}
