// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomatedMortgage {
    address public lender;
    uint public monthlyPayment;
    uint public totalAmount;
    uint public startDate;
    uint public duration; // in months

    struct Mortgage {
        address borrower;
        uint paidAmount;
        uint nextDueDate;
        bool isActive;
    }

    Mortgage public mortgage;

    event PaymentMade(address borrower, uint amount, uint date);
    event MortgageCompleted(address borrower);
    event MortgageTerminated(address borrower);

    modifier onlyLender() {
        require(msg.sender == lender, "Only lender can perform this action");
        _;
    }

    modifier onlyBorrower() {
        require(msg.sender == mortgage.borrower, "Only borrower can perform this action");
        _;
    }

    constructor(
        address _borrower,
        uint _monthlyPayment,
        uint _totalAmount,
        uint _durationMonths
    ) {
        lender = msg.sender;
        mortgage = Mortgage({
            borrower: _borrower,
            paidAmount: 0,
            nextDueDate: block.timestamp + 30 days,
            isActive: true
        });

        monthlyPayment = _monthlyPayment;
        totalAmount = _totalAmount;
        duration = _durationMonths;
        startDate = block.timestamp;
    }

    function makePayment() external payable onlyBorrower {
        require(mortgage.isActive, "Mortgage is not active");
        require(msg.value == monthlyPayment, "Incorrect payment amount");
        require(block.timestamp >= mortgage.nextDueDate, "Payment not due yet");

        mortgage.paidAmount += msg.value;
        mortgage.nextDueDate += 30 days;

        payable(lender).transfer(msg.value);
        emit PaymentMade(msg.sender, msg.value, block.timestamp);

        if (mortgage.paidAmount >= totalAmount) {
            mortgage.isActive = false;
            emit MortgageCompleted(msg.sender);
        }
    }

    function getRemainingBalance() external view returns (uint) {
        return totalAmount - mortgage.paidAmount;
    }

    function terminateMortgage() external onlyLender {
        require(mortgage.isActive, "Mortgage already completed or terminated");
        mortgage.isActive = false;
        emit MortgageTerminated(mortgage.borrower);
    }

    function getNextDueDate() external view returns (uint) {
        return mortgage.nextDueDate;
    }

    function isMortgageActive() external view returns (bool) {
        return mortgage.isActive;
    }
}

