// SPDX-License-Identifier: MIT
/*
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
+                                                                                                                 +
+                                                                                                                 +
.                        .^!!~:                                                 .^!!^.                            .
.                            :7Y5Y7^.                                       .^!J5Y7^.                             .
.                              :!5B#GY7^.                             .^!JP##P7:                                  .
.   7777??!         ~????7.        :[email protected]@@@&GY7^.                    .^!JG#@@@@G^        7????????????^ ~????77     .
.   @@@@@G          [email protected]@@@@:       J#@@@@@@@@@@&G57~.          .^7YG#@@@@@@@@@@&5:      #@@@@@@@@@@@@@? [email protected]@@@@@    .
.   @@@@@G          [email protected]@@@@:     :[email protected]@@@@[email protected]@@@@@@@@&B5?~:^7YG#@@@@@@@@[email protected]@@ @@&!!     #@@@@@@@@@@@@@? [email protected]@@@@@    .
.   @@@@@G          [email protected]@@@@:    [email protected]@@@#[email protected]@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@P   ^[email protected]@@@@~.   ^~~~~~^[email protected] @@@@??:~~~~~    .
.   @@@@@B^^^^^^^^. [email protected]@@@@:   [email protected]@@@&^   [email protected][email protected]@@@@@&@@@@@@@@@@@&@J7&@@@@@#.   [email protected]@@@P           [email protected]@@@@?            .
.   @@@@@@@@@@@@@@! [email protected]@@@@:   [email protected]@@@B   ^B&&@@@@@#!#@@@@@@@@@@7G&&@@@@@#!     [email protected]@@@#.           [email protected]@@@@?            .
.   @@@@@@@@@@@@@@! [email protected]@@@@:   [email protected]@@@&^    !YPGPY!  [email protected]@@@@Y&@@@@Y  ~YPGP57.    [email protected]@@@P           [email protected]@@@@?            .
.   @@@@@B~~~~~~~!!.?GPPGP:   [email protected]@@@&7           ?&@@@@P [email protected]@@@@5.          [email protected]@@@&^            [email protected]@@@@?            .
.   @@@@@G          ^~~~~~.    :[email protected]@@@@BY7~^^~75#@@@@@5.    [email protected]@@@@&P?~^^^[email protected]@@@@#~             [email protected]@@@@?            .
.   @@@@@G          [email protected]@@@@:      [email protected]@@@@@@@@@@@@@@@B!!      ^[email protected]@@@@@@@@@@@@@@@&Y               [email protected]@@@@?            .
.   @@@@@G.         [email protected]@@@@:        !YB&@@@@@@@@&BY~           ^JG#@@@@@@@@&#P7.                [email protected]@@@@?            .
.   YYYYY7          !YJJJJ.            :~!7??7!^:                 .^!7??7!~:                   ^YJJJY~            .
.                                                                                                                 .
.                                                                                                                 .
.                                                                                                                 .
.                                  ………………               …………………………………………                  …………………………………………        .
.   PBGGB??                      7&######&5            :B##############&5               .G#################^      .
.   &@@@@5                      [email protected]@@@@@@@@@           :@@@@@@@@@@@@@@@@@G               &@@@@@@@@@@@@ @@@@@^      .
.   PBBBBJ                 !!!!!JPPPPPPPPPY !!!!!     :&@@@@P?JJJJJJJJJJJJJJ?      :JJJJJJJJJJJJJJJJJJJJJJ.       .
.   ~~~~~:                .#@@@@Y          [email protected]@@@@~    :&@@@@7           [email protected]@@&.      ^@@@@.                        .
.   #@@@@Y                .#@@@@[email protected]@@@@~    :&@@@@7   !JJJJJJJJJJJJ?     :JJJJJJJJJJJJJJJJJ!!           .
.   #@@@@Y                .#@@@@@@@@@@@@@@@@@@@@@@~   :&@@@@7   [email protected]@@@@@@@G &@@             @@@@@@@@@@P            .
.   #@@@@Y                .#@@@@&##########&@@@@@~    :&@@@@7   7YYYYYYYYJ???7             JYYYYYYYYYYYYJ???7     .
.   #@@@@Y                .#@@@@5 ........ [email protected]@@@@~    :&@@@@7            [email protected]@@&.                         [email protected]@@#     .
.   #@@@@#5PPPPPPPPPJJ    .#@@@@Y          [email protected]@@@@~    :&@@@@P7??????????JYY5J      .?????????? ???????JYY5J       .
.   &@@@@@@@@@@@@@@@@@    .#@@@@Y          [email protected]@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@@@P            .
.   PBBBBBBBBBBBBBBBBY    .#@@@@Y          [email protected]@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@ @@5           .
+                                                                                                                 +
+                                                                                                                 +
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract HootBase is ReentrancyGuard, Pausable, Ownable {
    event PermissionChanged(address indexed addr, uint8 permission);

    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event ContractParsed();
    event ContractUnparsed();
    event ContractSealed();

    uint8 public constant NO_PERMISSION = 0;
    uint8 public constant MANAGER = 1;
    uint8 public constant MAINTAINER = 2;
    uint8 public constant OPERATOR = 3;

    mapping(address => uint8) private _permissions;
    address[] maintainers;

    bool public contractSealed = false;

    /***********************************|
    |               Config              |
    |__________________________________*/
    /**
     * @notice setManagerAddress is used to allow the issuer to modify the maintainerAddress
     */
    function setPermission(address address_, uint8 permission_)
        external
        onlyOwner
    {
        if (permission_ == NO_PERMISSION) {
            delete _permissions[address_];
        } else {
            _permissions[address_] = permission_;
        }

        emit PermissionChanged(address_, permission_);
    }

    function getPermissions()
        external
        view
        atLeastManager
        returns (address[] memory, uint8[] memory)
    {
        uint8[] memory permissions = new uint8[](maintainers.length);
        unchecked {
            for (uint256 i = 0; i < maintainers.length; i++) {
                permissions[i] = _permissions[maintainers[i]];
            }
        }
        return (maintainers, permissions);
    }

    function getPermission(address address_) external view returns (uint8) {
        return _permissions[address_];
    }

    /***********************************|
    |               Core                |
    |__________________________________*/
    /**
     * @notice issuer deposit ETH into the contract. only issuer have permission
     */
    function deposit() external payable atLeastMaintainer nonReentrant {
        emit Deposit(_msgSender(), msg.value);
    }

    /**
     * issuer withdraws the ETH temporarily stored in the contract through this method.
     */
    function withdraw(uint256 w) external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(w <= balance, "balance is not enough");
        payable(_msgSender()).transfer(w);
        emit Withdraw(_msgSender(), w);
    }

    /***********************************|
    |               Basic               |
    |__________________________________*/
    /**
     * @notice for the purpose of protecting user assets, under extreme conditions,
     * the circulation of all tokens in the contract needs to be frozen.
     * This process is under the supervision of the community.
     */
    function emergencyPause() external atLeastManager notSealed {
        _pause();
        emit ContractParsed();
    }

    /**
     * @notice unpause the contract
     */
    function unpause() external atLeastManager notSealed {
        _unpause();
        emit ContractUnparsed();
    }

    /**
     * @notice when the project is stable enough, the issuer will call sealContract
     * to give up the permission to call emergencyPause and unpause.
     */
    function sealContract() external onlyOwner {
        contractSealed = true;
        emit ContractSealed();
    }

    /***********************************|
    |               Modifier            |
    |__________________________________*/
    /**
     * @notice only owner or manager has the permission to call this method
     */
    modifier atLeastManager() {
        uint8 permission = _permissions[_msgSender()];
        require(
            owner() == _msgSender() || permission == MANAGER,
            "not authorized"
        );
        _;
    }
    /**
     * @notice only owner, manager or maintainer has the permission to call this method
     */
    modifier atLeastMaintainer() {
        uint8 permission = _permissions[_msgSender()];
        require(
            owner() == _msgSender() ||
                permission == MAINTAINER ||
                permission == MANAGER,
            "not authorized"
        );
        _;
    }
    /**
     * @notice only owner, manager or maintainer or operator has the permission to call this method
     */
    modifier atLeastOperator() {
        uint8 permission = _permissions[_msgSender()];
        require(
            owner() == _msgSender() ||
                permission == MAINTAINER ||
                permission == MANAGER ||
                permission == OPERATOR,
            "not authorized"
        );
        _;
    }

    /**
     * @notice for security reasons, CA is not allowed to call sensitive methods.
     */
    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "caller is another contract");
        _;
    }

    /**
     * @notice function call is only allowed when the contract has not been sealed
     */
    modifier notSealed() {
        require(!contractSealed, "contract sealed");
        _;
    }
}