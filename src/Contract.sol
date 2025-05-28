// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract  LendingandBorrowing {
    // Token balances for each user
    mapping(address => uint256) public depositBalances;

    // Borrowed amounts for each user
    mapping(address => uint256) public borrowBalances;

    // Collateral provided by each user
    mapping(address => uint256) public collateralBalances;

    // Interest rate in basis points (1/100 of a percent)
    // 500 basis points = 5% interest
    uint256 public interestRateBasisPoints = 500;

    // Collateral factor in basis points (e.g., 7500 = 75%)
    // Determines how much you can borrow against your collateral
    uint256 public collateralFactorBasisPoints = 7500;

    // Timestamp of last interest accrual
    mapping(address => uint256) public lastInterestAccrualTimestamp;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    
    //client will come and deposite their ethereum
    function deposit() external payable {
        require(msg.value > 0, "Insufficient amount");
        depositBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    //person who deposited in the pool now wants to withdraw 
    function withdraw(uint256 amount) external {
        require(depositBalances[msg.sender] >= amount, "Not enough balance");
        payable(msg.sender).transfer(amount);
        depositBalances[msg.sender] -= amount;
        emit Withdraw(msg.sender, amount);
    }

    //person who take the loan deposits the collateral 
    function depositCollateral() external payable {
        require(msg.value > 0,"Amount must be greater than zero");
        collateralBalances[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    //withdraw the collateral , after one had repaid the loan 
    // function withdrawCollateral(uint256 amount) external {
    //     require(amount <= collateralBalances[msg.sender]);
    //     uint256 finalAmount = calculateInterestAccrued(msg.sender);

    // }
    function borrow(uint256 amount) external {
        require(amount > 0);
        require(address(this).balance >= amount, "Insufficient balance");

        uint256 maxBorrowAmount = (collateralBalances[msg.sender] * collateralFactorBasisPoints) / 10000;
        uint256 currentDebt = calculateInterestAccrued(msg.sender);

        require(currentDebt + amount <= maxBorrowAmount);

        borrowBalances[msg.sender] += amount;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(amount);
        emit Borrow(msg.sender, amount);
        
    }
    function repay() external payable {
        require(msg.value > 0);
        uint256 currentdebt = calculateInterestAccrued(msg.sender);
        uint256 amountToRepay = msg.value;
        if(amountToRepay > currentdebt){
            amountToRepay = currentdebt;
            payable(msg.sender).transfer(msg.value - currentdebt);
        }

        borrowBalances[msg.sender] -= amountToRepay;
        lastInterestAccrualTimestamp[msg.sender] =block.timestamp;
    }
    function calculateInterestAccrued(address user) public view returns (uint256) {
         if (borrowBalances[user] == 0) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - lastInterestAccrualTimestamp[user];
        uint256 interest = (borrowBalances[user] * interestRateBasisPoints * timeElapsed) / (10000 * 365 days);

        return borrowBalances[user] + interest;
    }
    function getMaxBorrowAmount(address user) external view returns (uint256) {
        return (collateralBalances[user] * collateralFactorBasisPoints)/10000;
    }
    function getTotalLiquidity() external view returns (uint256) {
        return address(this).balance;
    }
}
