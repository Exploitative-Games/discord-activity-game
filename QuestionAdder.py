import questionary
import sqlite3

con = sqlite3.connect("dcgame.sqlite")

categories = {}

cur = con.cursor()

def updateCategories():
    cur.execute("SELECT id,name FROM categories")
    rows = cur.fetchall()
    for row in rows:
        categories[row[1]] = row[0]

def addQuestion(question: str, category: str, answers : str):
    cursor = con.cursor()
    cursor.execute("INSERT INTO questions (question, category_id, possible_answers) VALUES (?, ?, ?)", (question, category,answers))
    con.commit()
    return "Question added"


def addCategory(category: str):
    cursor = con.cursor()
    cursor.execute("INSERT INTO categories (name) VALUES (?)", (category,))
    con.commit()

    return "Category added"

import sys

def main():
    res = questionary.select("What do you want to do?", choices=["Add question", "Add category"]).ask()

    if res == "Add question":
        updateCategories()
        question = questionary.text("Enter the question").ask()
        category = questionary.autocomplete("Select category", choices={k for k in categories}).ask()
        answers = questionary.text("Enter the answers. Seperate with comma").ask()
        
        if answers == "Cancelled by user":
            main()

        print(addQuestion(question, categories[category], answers))
    elif res == "Add category":
        category = questionary.text("Enter the category").ask()
        if category == "Cancelled by user":
            main()
        print(addCategory(category))
    else:
        sys.exit(0) 
    main()
main()