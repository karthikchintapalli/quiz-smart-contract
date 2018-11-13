var expectThrow = require('./helper.js');
const Quiz = artifacts.require("Quiz");

contract("Quiz", async(accounts) => {
    var quiz;

    it("tests that two people can't register as quiz master", async () => {
        quiz = await Quiz.new({from: accounts[0]});
        let res1 = await quiz.register_quiz_master({from: accounts[0]});
        let res2 = quiz.register_quiz_master({from: accounts[1]});
        await expectThrow(res2);
    })

    it("tests that only quiz master can add questions", async () => {
        let res1 = quiz.add_question("Which is the greatest? - 1. 1 2. 2 3. 3 4. 4", 4, {from: accounts[1]});
        await expectThrow(res1);
    })

    it("tests for questions with valid answers", async () => {
        let res1 = quiz.add_question("Which is the greatest? - 1. 1 2. 2 3. 3 4. 4", 5, {from: accounts[0]});
        await expectThrow(res1);
    })

    it("tests that player can't register before start of registration", async () => {
        let res1 = quiz.register_player({from: accounts[1]});
        await expectThrow(res1);
    })

    it("tests that quiz master can't add questions after start of registration", async () => {
        let res4 = await quiz.add_question("Which is the greatest? - 1. 1 2. 2 3. 3 4. 4", 4, {from: accounts[0]});
        let res5 = await quiz.add_question("Which is the smallest? - 1. 1 2. 2 3. 3 4. 4", 1, {from: accounts[0]});
        let res6 = await quiz.add_question("Which is an even prime? - 1. 1 2. 2 3. 3 4. 4", 2, {from: accounts[0]});
        let res7 = await quiz.add_question("Which is an odd prime? - 1. 1 2. 2 3. 3 4. 4", 3, {from: accounts[0]});
        let res1 = await quiz.start_registration(10, 10, 40, {from: accounts[0]});
        let res2 = await quiz.register_player({from: accounts[1]});
        let res3 = quiz.add_question("Which is an even prime? - 1. 1 2. 2 3. 3 4. 4", 2, {from: accounts[0]});
        await expectThrow(res3);
    })

    it("tests that player can't pay arbitrary fee", async () => {
        let res1 = quiz.pay_reg_fee({from: accounts[1], value: 10e18});
        await expectThrow(res1);
    })

    it("tests that player can pay fee", async () => {
        let res1 = await quiz.pay_reg_fee({from: accounts[1], value: 16e18});
    })

    it("tests that quizmaster can't participate in quiz", async () => {
        let res1 = quiz.register_player({from: accounts[0]});
        await expectThrow(res1);
    })

    it("tests that players doesn't get question before quiz starts", async () => {
        let res1 = quiz.get_question({from: accounts[1]});
        await expectThrow(res1);
    })

    it("tests that players get question after quiz starts", async () => {
        var T = 10;
        while (T--) {
            await quiz.get_current_block();
        }
        let res1 = await quiz.get_question({from: accounts[1]});
    })

    it("tests that the player can submit an answer within question deadline", async () => {
        let res1 = await quiz.submit_answer(1, 4, {from: accounts[1]});
    })

    it("tests that an unregistered player cannot submit an answer", async () => {
        let res1 = quiz.submit_answer(1, 4, {from: accounts[3]});
        await expectThrow(res1);
    })

    it("tests that the player cannot submit an answer after question deadline", async () => {
        var T = 20;
        while (T--) {
            await quiz.get_current_block();
        }
        let res1 = quiz.submit_answer(2, 4, {from: accounts[1]});
        await expectThrow(res1);       
    })
    
    it("tests that the player cannot collect reward before quiz ends", async () => {
        let res1 = quiz.get_reward({from: accounts[1]});
        await expectThrow(res1);       
    })
    
    it("tests that the player and the quiz master can collect reward after quiz gets over", async () => {
        var T = 20;
        while (T--) {
            await quiz.get_current_block();
        }
        let res1 = await quiz.get_reward({from: accounts[1]});
        let res2 = await quiz.get_reward({from: accounts[0]});
        // await expectThrow(res1);       
    })

    it("tests that the player cannot collect reward twice", async () => {
        let res1 = quiz.get_reward({from: accounts[1]});
        await expectThrow(res1);       
    })

});
