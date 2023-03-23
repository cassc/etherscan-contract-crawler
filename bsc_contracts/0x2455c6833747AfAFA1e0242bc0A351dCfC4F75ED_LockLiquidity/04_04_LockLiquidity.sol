// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a, m);
        uint256 d = sub(c, 1);
        return mul(div(d, m), m);
    }
}

contract LockLiquidity is Ownable {
    using SafeMath for uint256;

    struct Items {
        address tokenAddress;
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 unlockTime;
        bool withdrawn;
    }

    uint256 public depositId;
    uint256[] public allDepositIds;
    mapping(address => uint256[]) public depositsByWithdrawalAddress;
    mapping(uint256 => Items) public lockedToken;
    mapping(address => mapping(address => uint256)) public walletTokenBalance;
    uint256 public lockServicePrice = 8000000000000000;

    event LogWithdrawal(address SentToAddress, uint256 AmountTransferred);

    /**
     *lock tokens
     */
    function lockTokens(
        address _tokenAddress,
        address _withdrawalAddress,
        uint256 _amount,
        uint256 _unlockTime
    ) public payable returns (uint256 _id) {
        require(_amount > 0, "amount should be > 0");
        require(
            _unlockTime >= block.timestamp,
            "unlockTime should be future date"
        );

        require(
            msg.value >= lockServicePrice,
            "sended value is lower than create token price"
        );

        payable(owner()).transfer(msg.value);

        //update balance in address
        walletTokenBalance[_tokenAddress][
            _withdrawalAddress
        ] = walletTokenBalance[_tokenAddress][_withdrawalAddress].add(_amount);

        _id = ++depositId;
        lockedToken[_id].tokenAddress = _tokenAddress;
        lockedToken[_id].withdrawalAddress = _withdrawalAddress;
        lockedToken[_id].tokenAmount = _amount;
        lockedToken[_id].unlockTime = _unlockTime;
        lockedToken[_id].withdrawn = false;

        allDepositIds.push(_id);
        depositsByWithdrawalAddress[_withdrawalAddress].push(_id);

        // transfer tokens into contract
        require(
            IERC20(_tokenAddress).transferFrom(
                msg.sender,
                address(this),
                _amount
            )
        );
    }

    function updateLockServicePrice(uint256 amount) public onlyOwner {
        lockServicePrice = amount;
    }

    /**
     *Extend lock Duration
     */
    function extendLockDuration(uint256 _id, uint256 _unlockTime) public {
        require(_unlockTime < 10000000000);
        require(_unlockTime > lockedToken[_id].unlockTime);
        require(!lockedToken[_id].withdrawn);
        require(msg.sender == lockedToken[_id].withdrawalAddress);

        //set new unlock time
        lockedToken[_id].unlockTime = _unlockTime;
    }

    /**
     *transfer locked tokens
     */
    function transferLocks(uint256 _id, address _receiverAddress) public {
        require(!lockedToken[_id].withdrawn);
        require(msg.sender == lockedToken[_id].withdrawalAddress);

        //decrease sender's token balance
        walletTokenBalance[lockedToken[_id].tokenAddress][
            msg.sender
        ] = walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender].sub(
            lockedToken[_id].tokenAmount
        );

        //increase receiver's token balance
        walletTokenBalance[lockedToken[_id].tokenAddress][
            _receiverAddress
        ] = walletTokenBalance[lockedToken[_id].tokenAddress][_receiverAddress]
            .add(lockedToken[_id].tokenAmount);

        //remove this id from sender address
        uint256 j;
        uint256 arrLength = depositsByWithdrawalAddress[
            lockedToken[_id].withdrawalAddress
        ].length;
        for (j = 0; j < arrLength; j++) {
            if (
                depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][
                    j
                ] == _id
            ) {
                depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][
                    j
                ] = depositsByWithdrawalAddress[
                    lockedToken[_id].withdrawalAddress
                ][arrLength - 1];
                depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress]
                    .pop();
                break;
            }
        }

        //Assign this id to receiver address
        lockedToken[_id].withdrawalAddress = _receiverAddress;
        depositsByWithdrawalAddress[_receiverAddress].push(_id);
    }

    /**
     *withdraw tokens
     */
    function withdrawTokens(uint256 _id) public {
        require(
            block.timestamp >= lockedToken[_id].unlockTime,
            "date before unlock date"
        );
        require(
            msg.sender == lockedToken[_id].withdrawalAddress,
            "caller should be withdrawalAddress"
        );
        require(!lockedToken[_id].withdrawn, "already withdrawn");

        lockedToken[_id].withdrawn = true;

        //update balance in address
        walletTokenBalance[lockedToken[_id].tokenAddress][
            lockedToken[_id].withdrawalAddress
        ] = walletTokenBalance[lockedToken[_id].tokenAddress][
            lockedToken[_id].withdrawalAddress
        ].sub(lockedToken[_id].tokenAmount);

        //remove this id from this address
        uint256 j;
        uint256 arrLength = depositsByWithdrawalAddress[
            lockedToken[_id].withdrawalAddress
        ].length;
        for (j = 0; j < arrLength; j++) {
            if (
                depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][
                    j
                ] == _id
            ) {
                depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][
                    j
                ] = depositsByWithdrawalAddress[
                    lockedToken[_id].withdrawalAddress
                ][arrLength - 1];
                depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress]
                    .pop();
                break;
            }
        }

        require(
            IERC20(lockedToken[_id].tokenAddress).transfer(
                lockedToken[_id].withdrawalAddress,
                lockedToken[_id].tokenAmount
            ),
            "caller should be owner of lock"
        );
        emit LogWithdrawal(
            lockedToken[_id].withdrawalAddress,
            lockedToken[_id].tokenAmount
        );
    }

    /*get total token balance in contract*/
    function getTotalTokenBalance(
        address _tokenAddress
    ) public view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    /*get total token balance by address*/
    function getTokenBalanceByAddress(
        address _tokenAddress,
        address _walletAddress
    ) public view returns (uint256) {
        return walletTokenBalance[_tokenAddress][_walletAddress];
    }

    /*get allDepositIds*/
    function getAllDepositIds() public view returns (uint256[] memory) {
        return allDepositIds;
    }

    /*get getDepositDetails*/
    function getDepositDetails(
        uint256 _id
    )
        public
        view
        returns (
            address _tokenAddress,
            address _withdrawalAddress,
            uint256 _tokenAmount,
            uint256 _unlockTime,
            bool _withdrawn
        )
    {
        return (
            lockedToken[_id].tokenAddress,
            lockedToken[_id].withdrawalAddress,
            lockedToken[_id].tokenAmount,
            lockedToken[_id].unlockTime,
            lockedToken[_id].withdrawn
        );
    }

    /*get DepositsByWithdrawalAddress*/
    function getDepositsByWithdrawalAddress(
        address _withdrawalAddress
    ) public view returns (uint256[] memory) {
        return depositsByWithdrawalAddress[_withdrawalAddress];
    }
}