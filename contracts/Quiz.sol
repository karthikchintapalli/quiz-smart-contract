pragma solidity ^0.4.24;

contract Quiz{

    address[] players_adds;

    uint N;
    uint player_count;
    uint starttime;
    uint endtime;
    uint question_count;
    uint total_pfee;
    address quiz_master;
    bool quiz_master_reward_collected;
    bool registration_started;
    uint time;

    constructor() public {
        N = 10;
        player_count = 0;
        starttime = 0;
        endtime = 0;
        question_count = 0;
        total_pfee = 0;
    }

    modifier onlyQuizMaster () {
        require (msg.sender == quiz_master, "not the quiz master");
        _;
    }
    modifier quizmasterDoesNotExist () {
        require (quiz_master == 0, "Quiz master exists");
        _;
    }

    modifier onlyBy(address _account) {
        require(msg.sender == _account, "Late");
        _;
    }

    modifier onlyBefore(uint _time) {
        require(block.number < _time, "too late");
        _;
    }

    modifier onlyAfter(uint _time) {
        require(block.number > _time, "too early");
        _;
    }

    modifier isRegistered(address _add) {
        require(add_to_player[_add].pending == true || add_to_player[_add].paid == true, "Not registered");
        _;
    }

    modifier hasPaid(address _add) {
        require(add_to_player[_add].paid == true, "Not paid");
        _;
    }

    modifier hasPaidorQuizMaster(address _add) {
        require(add_to_player[_add].paid == true || _add == quiz_master, "Not a part of the system");
        _;
    }

    modifier hasNotAnsweredQuestion (address _add, uint _qno) {
        require(question_details[_qno - 1].answers[_add] == 0, "Already Answered");
        _;
    }

    modifier playerCountInLimit() {
        require (player_count > 0 && player_count <= N);
        _;
    }

    struct Player {
        uint p_fee;
        uint reward;
        uint answer;
        bool pending;
        bool paid;
        bool is_reward_collected;
    }

    struct Question {
        uint starttime;
        uint endtime;
        string text;
        uint correct_ans;
        mapping (address => uint) answers;
        bool won_over;
        address winner;
    }

    struct QuizMaster {
        address add;
    }

    mapping (uint => Question) question_details;
    mapping (address => Player) add_to_player;

    function register_quiz_master () public
    quizmasterDoesNotExist
    returns(bool) {
        quiz_master = msg.sender;
    }

    function add_question (string _ques, uint _ans) public
    onlyQuizMaster
    returns (bool) {
        require(registration_started == false, "Participants registration started");
        require(_ans > 0 && _ans < 5, "Invalid answer");
        question_details[question_count].text = _ques;
        question_details[question_count].correct_ans = _ans;
        question_count = question_count + 1;
    }

    function start_registration (uint _N, uint _st_off, uint _et_off) public
    onlyQuizMaster
    returns(bool) {
        require(registration_started == false, "Registration already started");
        require(question_count > 0, "No questions");

        N = _N;
        starttime = block.number + _st_off;
        endtime = starttime + _et_off;

        uint i;
        for(i = 0; i < question_count; i++) {
            question_details[i].starttime = starttime + i*(endtime - starttime)/question_count;
            question_details[i].endtime = starttime + (i+1)*(endtime - starttime)/question_count;
        }

        registration_started = true;

        return true;
    }

    function register_player() public onlyBefore(starttime) returns(bool) {
        require(registration_started == true, "Registration has not started yet");
        require(msg.sender != quiz_master, "You are not allowed, good sir.");
        require(player_count < N, "Number of players exceed the max. count of players allowed");
        require(!add_to_player[msg.sender].paid && !add_to_player[msg.sender].pending, "Pending or paid already");

        Player storage p = add_to_player[msg.sender];
        p.pending = true;
        p.paid = false;
        p.reward = 0;
        p.answer = 0;
        p.p_fee = calc_entry_fee();
        return true;
    }

    function calc_entry_fee() public returns(uint) {
        return 16e18;
    }

    function get_entry_fee() public view isRegistered(msg.sender) returns(uint) {
        // require(add_to_player[msg.sender].pending == true || add_to_player[msg.sender].paid == true, "Not registered");
        require(registration_started == true, "Registration has not started.");
        require(msg.sender != quiz_master, "You are the quiz master.");
        return add_to_player[msg.sender].p_fee;
        // return block.number;
    }

    function pay_reg_fee() payable public onlyBefore(starttime) returns(bool) {
        require(add_to_player[msg.sender].pending == true, "Not pending");
        require(add_to_player[msg.sender].paid == false, "Fee already paid!");
        require(msg.value == add_to_player[msg.sender].p_fee, "Amount paid does not match entry fee");
        require(msg.sender != quiz_master, "You are the quiz master.");


        Player storage p = add_to_player[msg.sender];
        p.paid = true;
        p.pending = false;

        player_count = player_count + 1;
        total_pfee = total_pfee + msg.value;

        return true;
    }

    function get_quiz_start_time() public view isRegistered(msg.sender) returns(uint) {
        return starttime;
    }


    function get_quiz_end_time() public view isRegistered(msg.sender) returns(uint) {
        return endtime;
    }

    function get_question() public
    onlyAfter(starttime)
    onlyBefore(endtime)
    hasPaid(msg.sender) view returns(string) {
        // require(add_to_player[msg.sender].paid == true, "You haven't paid or haven't registered.");
        uint i;
        for(i = 0; i < question_count; i++) {
            if(question_details[i].endtime > block.number && question_details[i].starttime <= block.number) {
                // question_details[i].if_viewed[msg.sender] = true;
                return question_details[i].text;
            }
        }
    }

    function submit_answer(uint _qno, uint _ans) public
    onlyAfter(starttime)
    onlyBefore(endtime)
    hasPaid(msg.sender)
    hasNotAnsweredQuestion(msg.sender, _qno) returns(bool) {

        require(_ans > 0 && _ans < 5, "Invalid response");
        require(msg.sender != quiz_master, "You are the quiz master. You cannot answer the questions.");

        uint i;
        for(i = 0; i < question_count; i++) {

            if(question_details[i].endtime > block.number && question_details[i].starttime <= block.number) {

                require(_qno - 1 == i, "Not in the current question session");

                question_details[i].answers[msg.sender] = _ans;

                if(question_details[i].won_over == false && _ans == question_details[i].correct_ans)  {
                    question_details[i].won_over = true;
                    question_details[i].winner = msg.sender;
                    return true;
                }
                else {
                    return false;
                }

            }
        }
    }

    function get_reward() public
    onlyAfter(endtime)
    hasPaidorQuizMaster(msg.sender)
    returns(uint) {
        require(((msg.sender == quiz_master && quiz_master_reward_collected == true) || add_to_player[msg.sender].is_reward_collected == false) && !((msg.sender == quiz_master && quiz_master_reward_collected == true) && add_to_player[msg.sender].is_reward_collected == false), "You have already collected your reward");

        uint reward = 0;
        uint i;

        if(msg.sender == quiz_master) {

            for(i = 0; i < question_count; i++) {
                if(question_details[i].winner == 0) {
                    reward = reward + (3 * total_pfee) / (4 * question_count);
                }
            }
            reward = reward + total_pfee / 4;
            msg.sender.transfer(reward);
            quiz_master_reward_collected = true;
        }

        else if(msg.sender != quiz_master) {
            reward = 0;
            for(i = 0; i < question_count; i++) {
                if(msg.sender == question_details[i].winner) {
                    reward = reward + (3 * total_pfee) / (4 * question_count);
                }
            }
            msg.sender.transfer(reward);
            add_to_player[msg.sender].is_reward_collected = true;
        }
        return reward;
    }

    // function view_start_time() public view returns(uint) {
    //     return block.number; 
    // }

    function get_current_block() public payable returns(uint) {
        time  = time + 1;
        return block.number;
    }

}
