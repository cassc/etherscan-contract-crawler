/*

 _______   _______ .___  ___.  __    _______ .______        ___   .___________. _______ 
|   ____| /  _____||   \/   | |  |  /  _____||   _  \      /   \  |           ||   ____|
|  |__   |  |  __  |  \  /  | |  | |  |  __  |  |_)  |    /  ^  \ `---|  |----`|  |__   
|   __|  |  | |_ | |  |\/|  | |  | |  | |_ | |      /    /  /_\  \    |  |     |   __|  
|  |____ |  |__| | |  |  |  | |  | |  |__| | |  |\  \   /  _____  \   |  |     |  |____ 
|_______| \______| |__|  |__| |__|  \______| | _| `._\_/__/     \__\  |__|     |_______|
                                                                                          

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./OwnableUpgradeable.sol";

contract EGMigrate is OwnableUpgradeable {
    struct MigrationToken {
        uint256 index; // index of the source token
        address targetToken; // target token address
        uint256 rate; // migration ratio
        address devAddress; // the address to send the source tokens that are received from holders
        uint256 amountOfMigratedSourceToken; // total amount of migrated source tokens
        uint256 amountOfMigratedTargetToken; // total amount of migrated target tokens
        uint256 numberOfMigrators; // total number of migrators
        bool isPresent; // is this token present as a supported migration token
        bool enabled; // is migration enabled for this token
    }

    struct Migration {
        uint256 migrationId;
        address toAddress;
        uint256 timestamp;
        uint256 amountOfSourceToken;
        uint256 amountOfTargetToken;
    }

    /**
     * @dev counter for source tokens
     **/
    uint256 public sourceTokenCounter;

    /**
     * @dev mapping of source token address to migration
     **/
    mapping(address => MigrationToken) public migrationTokens;
    /**
     * @dev mapping of source token index to source token address
     **/
    mapping(uint256 => address) public sourceTokenIndices;

    /**
     * @dev counter for all migrations
     **/
    uint256 public migrationCounter;
    /**
     * @dev mapping of source token address to mapping of user address to array of Migrations
     **/
    mapping(address => mapping(address => Migration[])) private _userMigrations;

    /**
     * @param sourceToken source token address
     * @param targetToken target token address
     * @param rate rate of migration
     * @param devAddress the address to send the source tokens to
     *
     * @dev Emitted when add migration token
     **/
    event AddMigrationToken(
        address indexed sourceToken,
        address indexed targetToken,
        uint256 rate,
        address indexed devAddress
    );
    /**
     * @param token source token address
     * @param status status of migration
     *
     * @dev Emitted when set migration token status
     **/
    event SetStatusOfMigrationToken(address indexed token, bool status);
    /**
     * @param sourceToken source token address
     * @param targetToken target token address
     * @param rate rate of migration
     * @param devAddress the address to send the source tokens to
     *
     * @dev Emitted when add update migration token info
     **/
    event UpdateMigrationTokenInfo(
        address indexed sourceToken,
        address indexed targetToken,
        uint256 rate,
        address indexed devAddress
    );
    /**
     * @param fromAddress migrator wallet address
     * @param toAddress address to send the new tokens to holder
     * @param sourceToken source token address
     * @param amountOfSourceToken amount of source token address
     * @param targetToken target token
     * @param amountOfTargetToken amount of target token
     * @dev Emitted when migrate token
     **/
    event Migrate(
        address indexed fromAddress,
        address toAddress,
        address indexed sourceToken,
        uint256 amountOfSourceToken,
        address indexed targetToken,
        uint256 amountOfTargetToken
    );
    /**
     * @param sourceToken source token address
     * @param toAddress wallet address to return the source tokens to
     * @param amount amount of source token
     * @dev Emitted when return unused tokens back to dev team
     **/
    event TokensReturned(
        address indexed sourceToken,
        address indexed toAddress,
        uint256 amount
    );

    /**
     * @dev function that can be invoked at most once
     * @dev Initializes the contract setting the deployer as the initial owner.
     **/
    function initialize() external initializer {
        __Ownable_init();
    }

    /**
     * @param sourceToken source token address
     * @param targetToken target token address
     * @param rate migration ratio
     * @param devAddress the address to send the source tokens to

     * @dev add migration token
     **/
    function addMigrationToken(
        address sourceToken,
        address targetToken,
        uint256 rate,
        address devAddress
    ) external onlyOwner {
        require(
            sourceToken != address(0),
            "EGMigrate: source token address is zero"
        );
        require(
            !migrationTokens[sourceToken].isPresent,
            "EGMigrate: source token already exists"
        );
        require(
            targetToken != address(0),
            "EGMigrate: target token address is zero"
        );
        require(
            sourceToken != targetToken,
            "EGMigrate: sourceToken is the same as tragetToken"
        );
        require(0 < rate, "EGMigrate: rate is zero");

        MigrationToken memory migrationToken = MigrationToken({
            index: sourceTokenCounter,
            targetToken: targetToken,
            rate: rate,
            devAddress: devAddress,
            amountOfMigratedSourceToken: 0,
            amountOfMigratedTargetToken: 0,
            numberOfMigrators: 0,
            isPresent: true,
            enabled: true
        });

        migrationTokens[sourceToken] = migrationToken;
        sourceTokenIndices[sourceTokenCounter] = sourceToken;
        sourceTokenCounter = sourceTokenCounter + 1;

        emit AddMigrationToken(sourceToken, targetToken, rate, devAddress);
    }

    /**
     * @param sourceToken source token address
     * @param status status of migration

     * @dev enable migration token
     **/
    function setStatusOfMigrationToken(address sourceToken, bool status)
        external
        onlyOwner
    {
        require(
            migrationTokens[sourceToken].isPresent,
            "EGMigrate: source token does not exist"
        );

        migrationTokens[sourceToken].enabled = status;

        emit SetStatusOfMigrationToken(sourceToken, status);
    }

    /**
     * @param sourceToken source token address
     * @param targetToken target token address
     * @param rate migration ratio
     * @param devAddress the address to send the source tokens to

     * @dev update migration token info
     **/
    function updateMigrationTokenInfo(
        address sourceToken,
        address targetToken,
        uint256 rate,
        address devAddress
    ) external onlyOwner {
        require(
            migrationTokens[sourceToken].isPresent,
            "EGMigrate: source token does not exist"
        );
        require(
            targetToken != address(0),
            "EGMigrate: target token address is zero"
        );
        require(
            sourceToken != targetToken,
            "EGMigrate: sourceToken is the same as tragetToken"
        );
        require(0 < rate, "EGMigrate: rate is zero");

        migrationTokens[sourceToken].targetToken = targetToken;
        migrationTokens[sourceToken].devAddress = devAddress;
        migrationTokens[sourceToken].rate = rate;

        emit UpdateMigrationTokenInfo(
            sourceToken,
            targetToken,
            rate,
            devAddress
        );
    }

    /**
     * @param token source token address
     * @param toAddress address to send the new tokens to holder
     * @param amount amount of source tokens to migrate
     *
     * @dev migrate token
     **/
    function migrate(
        address token,
        address toAddress,
        uint256 amount
    ) external {
        require(
            migrationTokens[token].isPresent,
            "EGMigrate: source token does not exist"
        );
        require(
            migrationTokens[token].enabled,
            "EGMigrate: migration is disabled for this token"
        );
        require(
            toAddress != address(0),
            "EGMigrate: transfer to the zero address is not allowed"
        );
        require(0 < amount, "EGMigrate: amount is zero");

        MigrationToken storage migrationToken = migrationTokens[token];

        require(
            amount <= IERC20(token).balanceOf(_msgSender()),
            "EGMigrate: insufficient balance of source token in holder wallet"
        );
        require(
            amount <= IERC20(token).allowance(_msgSender(), address(this)),
            "EGMigrate: holder has insufficient approved allowance for source token"
        );

        uint256 migrationAmount = (amount *
            (10**IERC20Metadata(migrationToken.targetToken).decimals())) /
            (10**IERC20Metadata(token).decimals()) /
            (migrationToken.rate);

        require(
            migrationAmount <
                IERC20(migrationToken.targetToken).balanceOf(address(this)),
            "EGMigrate: insufficient balance of target token"
        );

        IERC20(token).transferFrom(
            _msgSender(),
            migrationToken.devAddress,
            amount
        );
        migrationToken.amountOfMigratedSourceToken =
            migrationToken.amountOfMigratedSourceToken +
            amount;

        IERC20(migrationToken.targetToken).transfer(toAddress, migrationAmount);
        migrationToken.amountOfMigratedTargetToken =
            migrationToken.amountOfMigratedTargetToken +
            migrationAmount;

        Migration[] storage userTxns = _userMigrations[token][_msgSender()];
        if (userTxns.length == 0) {
            migrationToken.numberOfMigrators =
                migrationToken.numberOfMigrators +
                1;
        }

        userTxns.push(
            Migration({
                migrationId: migrationCounter,
                toAddress: toAddress,
                timestamp: block.timestamp,
                amountOfSourceToken: amount,
                amountOfTargetToken: migrationAmount
            })
        );
        _userMigrations[token][_msgSender()] = userTxns;

        migrationCounter = migrationCounter + 1;

        emit Migrate(
            _msgSender(),
            toAddress,
            token,
            amount,
            migrationToken.targetToken,
            migrationAmount
        );
    }

    /**
     * @param sourceToken source token address
     * @param userAddress address of user
     *
     * @dev get total number of user migrations
     */
    function userMigrationsLength(address sourceToken, address userAddress)
        external
        view
        returns (uint256)
    {
        return _userMigrations[sourceToken][userAddress].length;
    }

    /**
     * @param sourceToken source token address
     * @param userAddress address of user
     * @param index index of user migration
     *
     * @dev get user migration log with index
     */
    function userMigration(
        address sourceToken,
        address userAddress,
        uint256 index
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Migration storage txn = _userMigrations[sourceToken][userAddress][
            index
        ];

        return (
            txn.migrationId,
            txn.timestamp,
            txn.amountOfSourceToken,
            txn.amountOfTargetToken
        );
    }

    /**
     * @param token source token address
     * @param toAddress wallet address to return the source tokens to
     * @param amount amount of source token
     *
     * @dev return unused tokens back to dev team
     */
     function returnTokens(
        address token,
        address toAddress,
        uint256 amount
    ) external onlyOwner {
        require(amount > 0, "EGMigrate: Amount should be greater than zero");
        require(
            toAddress != address(0),
            "ERC20: transfer to the zero address is not allowed"
        );
        require(
            migrationTokens[token].isPresent,
            "ERC20: source token does not exist"
        );
        require(
                IERC20(migrationTokens[token].targetToken).balanceOf(
                    address(this)
                ) >= amount,
            "EGMigrate: Target token balance in contract is insufficient"
        );

        MigrationToken storage migrationToken = migrationTokens[token];
        IERC20(migrationToken.targetToken).transfer(toAddress, amount);

        emit TokensReturned(migrationToken.targetToken, toAddress, amount);
    }
}