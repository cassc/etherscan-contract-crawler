// SPDX-License-Identifier: MIT

interface ICocktailNFT is IERC721 {
    function minted() external view returns (uint256);

    function safeMint(address to) external;
}

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SpeakEasyBuyer is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    ///@dev no constructor in upgradable contracts. Instead we have initializers
    function initialize() public initializer {
        ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
        __Ownable_init();
        SILVER_ADDRESS = 0xaC256FB4e7D7D2a882A4c2BE327a031b9cE78FEE;
        GOLD_ADDRESS = 0x284744e6D901e5aB25d918dD1dF3Eb0C2f1dF0a4;
        EMP_SILVER_ADDRESS = 0xc78BB9c34CdF873FcCF787AF8d84DE42af45c540;

        STAFF_ADDRESS = 0x90849d08168D8D665cb45ae4BD3f9E6037C6E365;
        RECEIVER_ADDRESS = 0xD0FE38Fb6e85e8A228A8A2EB3288a3eabD036924;
        OWNER_ADDRESS = _msgSender();
        _staff = payable(STAFF_ADDRESS);
        _receiver = payable(RECEIVER_ADDRESS);
        _owner = payable(OWNER_ADDRESS);

        _EMPsilverMKCNFT = ICocktailNFT(EMP_SILVER_ADDRESS);
        _silverMKCNFT = ICocktailNFT(SILVER_ADDRESS);
        _goldMKCNFT = ICocktailNFT(GOLD_ADDRESS);

        _BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        _USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);

        _NOT_ENTERED = 1;
        _ENTERED = 2;
        _status = _NOT_ENTERED;
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    ICocktailNFT public _EMPsilverMKCNFT;
    ICocktailNFT public _silverMKCNFT;
    ICocktailNFT public _goldMKCNFT;

    address private EMP_SILVER_ADDRESS;
    address private SILVER_ADDRESS;
    address private GOLD_ADDRESS;

    address private STAFF_ADDRESS;
    address private RECEIVER_ADDRESS;
    address private OWNER_ADDRESS;
    address payable internal _staff;
    address payable internal _receiver;
    address payable internal _owner;

    IERC20 public _BUSD;
    IERC20 public _USDT;

    bool public membershipRequiredDisabled;
    bool public depositBUSDEnabled;
    bool public depositUSDTEnabled;
    bool public depositBNBEnabled;

    uint256 private _NOT_ENTERED;
    uint256 private _ENTERED;
    uint256 private _status;

    event LogBytes(bytes data);

    // Added in version 2
    IERC20 public _DRINKS;
    bool public depositDRINKSEnabled;

    function initiateDrinks(address drinks) public onlyTeam {
        _DRINKS = IERC20(drinks);
    }
    ////////////////////////

    modifier onlyTeam() {
        require(msg.sender == STAFF_ADDRESS || msg.sender == OWNER_ADDRESS);
        _;
    }

    function updateReceiverAddress(address newReceiver) public onlyTeam {
        RECEIVER_ADDRESS = newReceiver;
    }

    function depositBUSD(uint256 tokens) public nonReentrant {
        require(depositBUSDEnabled == true, "BUSD deposit not enabled");
        require(
            membershipRequiredDisabled || hasMembership(msg.sender),
            "Membership required"
        );

        bool success = _BUSD.transferFrom(
            address(msg.sender),
            address(this),
            tokens
        );
        if (success == false) {
            revert("BUSD token transfer failed!");
        }

        _BUSD.transfer(RECEIVER_ADDRESS, tokens);
    }

    function depositUSDT(uint256 tokens) public nonReentrant {
        require(depositUSDTEnabled == true, "USDT deposit not enabled");
        require(
            membershipRequiredDisabled || hasMembership(msg.sender),
            "Membership required"
        );

        bool success = _USDT.transferFrom(
            address(msg.sender),
            address(this),
            tokens
        );
        if (success == false) {
            revert("USDT token transfer failed!");
        }

        _USDT.transfer(RECEIVER_ADDRESS, tokens);
    }

    function depositDRINKS(uint256 tokens) public nonReentrant {
        require(depositDRINKSEnabled == true, "DRINKS deposit not enabled");
        require(
            membershipRequiredDisabled || hasMembership(msg.sender),
            "Membership required"
        );

        bool success = _DRINKS.transferFrom(
            address(msg.sender),
            address(this),
            tokens
        );
        if (success == false) {
            revert("DRINKS token transfer failed!");
        }

        _DRINKS.transfer(RECEIVER_ADDRESS, tokens);
    }

    function depositBNB() public payable nonReentrant {
        require(depositBNBEnabled == true, "BNB deposit not enabled");
        require(
            membershipRequiredDisabled || hasMembership(msg.sender),
            "Membership required"
        );

        _receiver.transfer(msg.value);
    }

    function toggleMembershipRequirement(bool enable) public onlyTeam {
        membershipRequiredDisabled = enable ? false : true;
    }

    function toggleDepositBUSD(bool enable) public onlyTeam {
        depositBUSDEnabled = enable;
    }

    function toggleDepositUSDT(bool enable) public onlyTeam {
        depositUSDTEnabled = enable;
    }

    function toggleDepositDRINKS(bool enable) public onlyTeam {
        depositDRINKSEnabled = enable;
    }

    function toggleDepositBNB(bool enable) public onlyTeam {
        depositBNBEnabled = enable;
    }

    function hasMembership(address adr) public view returns (bool) {
        return
            _silverMKCNFT.balanceOf(adr) > 0 ||
            _EMPsilverMKCNFT.balanceOf(adr) > 0 ||
            _goldMKCNFT.balanceOf(adr) > 0;
    }
}