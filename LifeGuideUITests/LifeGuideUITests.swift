import XCTest

final class LifeGuideUITests: XCTestCase {
    @MainActor func testWidgetArticleLinks() throws {
        let app = XCUIApplication()
        app.launchEnvironment["GUIDE_LANGUAGE"] = "zh-Hans"
        app.launch()
        app.open(URL(string: "lifeguide://article?id=1-1&language=en")!)
        XCTAssertTrue(app.buttons["saveArticle"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Always wear seat belts, both front and back"].firstMatch.exists)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.tabBars.buttons["Guide"].exists)
        app.terminate()
        app.open(URL(string: "lifeguide://article?id=1-1&language=zh-Hans")!)
        XCTAssertTrue(app.buttons["saveArticle"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["系安全带，前排后排都系"].firstMatch.exists)
    }

    @MainActor func testSearchSavePlanAndPersistence() throws {
        let app = XCUIApplication()
        app.launchEnvironment["GUIDE_LANGUAGE"] = "zh-Hans"
        app.launch()
        app.tabBars.buttons["指南"].tap()
        let search = app.searchFields.firstMatch
        if !search.exists { app.swipeDown() }
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("系安全带")
        let article = app.staticTexts["系安全带，前排后排都系"].firstMatch
        XCTAssertTrue(article.waitForExistence(timeout: 5))
        article.tap()
        let save = app.buttons["saveArticle"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        if save.label == "取消收藏" { save.tap() }
        save.tap()
        XCTAssertEqual(save.label, "取消收藏")
        let plan = app.buttons["planArticle"]
        if plan.label.contains("已加入") { plan.tap() }
        plan.tap()
        XCTAssertTrue(plan.label.contains("已加入"))
        app.terminate()
        app.launch()
        app.tabBars.buttons["收藏"].tap()
        XCTAssertTrue(app.staticTexts["系安全带，前排后排都系"].waitForExistence(timeout: 5))
        app.tabBars.buttons["行动"].tap()
        let complete = app.buttons["complete-1-1"]
        XCTAssertTrue(complete.waitForExistence(timeout: 5))
        complete.tap()
        XCTAssertEqual(complete.label, "标为未完成")
        app.staticTexts["系安全带，前排后排都系"].tap()
        XCTAssertFalse(app.buttons["viewSource"].exists)
    }
    @MainActor func testFullArticleAndPDFAreFree() throws {
        let app = XCUIApplication()
        app.launchEnvironment["GUIDE_LANGUAGE"] = "zh-Hans"
        app.launch()
        app.tabBars.buttons["指南"].tap()
        let search = app.searchFields.firstMatch
        if !search.exists { app.swipeDown() }
        search.tap()
        search.typeText("燃气软管")
        app.staticTexts["燃气软管和灶具到期就换，不自己改管道，燃气公司上门推销可以直接拒绝"].firstMatch.tap()
        XCTAssertTrue(app.buttons["saveArticle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["planArticle"].exists)
        app.terminate()
        app.launch()
        app.buttons["关于与内容来源"].tap()
        for _ in 0..<8 {
            if app.buttons["阅读本节导言"].isHittable { break }
            app.swipeUp()
        }
        app.buttons["阅读本节导言"].tap()
        app.buttons["打开原文排版（含表格）"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["sourcePDF"].waitForExistence(timeout: 5))
    }

    @MainActor func testAllLanguagesAndPersistedSelection() throws {
        let app = XCUIApplication()
        app.launchEnvironment["GUIDE_LANGUAGE"] = "zh-Hans"
        app.launch()
        let editions = [
            ("en", "Guide", "665"), ("ru", "Гид", "665"),
            ("es", "Guía", "665"), ("pt", "Guia", "665"),
            ("vi", "Cẩm nang", "641"), ("ar", "الدليل", "635"),
            ("id", "Panduan", "630"), ("zh-Hans", "指南", "672")
        ]
        for (code, tab, count) in editions {
            app.buttons["languagePicker"].tap()
            app.buttons["language-\(code)"].tap()
            XCTAssertTrue(app.tabBars.buttons[tab].waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts[count].exists)
        }
        app.buttons["languagePicker"].tap()
        app.buttons["language-en"].tap()
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "GUIDE_LANGUAGE")
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Guide"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Guide"].tap()
        let search = app.searchFields.firstMatch
        if !search.exists { app.swipeDown() }
        search.tap()
        search.typeText("seat belts")
        let result = app.staticTexts["Always wear seat belts, both front and back"].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        result.tap()
        XCTAssertTrue(app.buttons["saveArticle"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["viewSource"].exists)
        for _ in 0..<10 {
            if app.descendants(matching: .any)["translationSource"].isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(app.descendants(matching: .any)["translationSource"].exists)
    }

}
