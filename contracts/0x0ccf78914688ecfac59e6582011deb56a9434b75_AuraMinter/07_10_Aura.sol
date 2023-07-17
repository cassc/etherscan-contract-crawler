// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { ERC20 } from "@openzeppelin/contracts-0.8/token/ERC20/ERC20.sol";
import { AuraMath } from "../utils/AuraMath.sol";
import { IFireproofTokenMinter } from "../interfaces/IFireproofTokenMinter.sol";
import { IKaiToken } from "../interfaces/IKaiToken.sol";

/**
 * @title   AuraToken
 * @notice  Basically an ERC20 with minting functionality operated by the DAO.
 * @dev     The minting schedule is based on the amount of CRV earned through staking and is
 *          distributed along a supply curve (cliffs etc). Fork of Aura (and originally ConvexToken).
 */
contract AuraToken is IKaiToken, ERC20, IFireproofTokenMinter {
    using AuraMath for uint256;

    address public operator;
    mapping(address => bool) public allowedMinters;

    uint256 public constant EMISSIONS_MAX_SUPPLY = 5e25; // 50m
    uint256 public constant INIT_MINT_AMOUNT = 5e25; // 50m
    uint256 public constant totalCliffs = 500;
    uint256 public immutable reductionPerCliff;

    address public minter;
    uint256 private minterMinted = type(uint256).max;

    /* ========== EVENTS ========== */

    event Initialised();

    /**
     * @param _nameArg      Token name
     * @param _symbolArg    Token symbol
     */
    constructor(string memory _nameArg, string memory _symbolArg) ERC20(_nameArg, _symbolArg) {
        operator = msg.sender;
        reductionPerCliff = EMISSIONS_MAX_SUPPLY.div(totalCliffs);
    }

    /**
     * @dev Initialise and mints initial supply of tokens.
     * @param _to        Target address to mint.
     * @param _minter    The minter address.
     */
    function init(address _to, address _minter) external {
        require(msg.sender == operator, "Only operator");
        require(totalSupply() == 0, "Only once");
        require(_minter != address(0), "Invalid minter");

        _mint(_to, INIT_MINT_AMOUNT);
        minter = _minter;
        minterMinted = 0;

        emit Initialised();
    }

    function setAllowedMinter(address _minter, bool _isAllowed) external {
        require(msg.sender == operator, "Only operator");
        allowedMinters[_minter] = _isAllowed;
    }

    /**
     * @dev Mints AURA to a given user based on the BAL supply schedule.
     */
    function mint(address _to, uint256 _amount) external {
        require(totalSupply() != 0, "Not initialised");

        if (msg.sender != operator) {
            // dont error just return. if a shutdown happens, rewards on old system
            // can still be claimed, just wont mint cvx
            return;
        }

        // e.g. emissionsMinted = 6e25 - 5e25 - 0 = 1e25;
        uint256 emissionsMinted = totalSupply() - INIT_MINT_AMOUNT - minterMinted;
        // e.g. reductionPerCliff = 5e25 / 500 = 1e23
        // e.g. cliff = 1e25 / 1e23 = 100
        uint256 cliff = emissionsMinted.div(reductionPerCliff);

        // e.g. 100 < 500
        if (cliff < totalCliffs) {
            // e.g. (new) reduction = (500 - 100) * 2.5 + 700 = 1700;
            // e.g. (new) reduction = (500 - 250) * 2.5 + 700 = 1325;
            // e.g. (new) reduction = (500 - 400) * 2.5 + 700 = 950;
            uint256 reduction = totalCliffs.sub(cliff).mul(5).div(2).add(700);
            // e.g. (new) amount = 1e19 * 1700 / 500 =  34e18;
            // e.g. (new) amount = 1e19 * 1325 / 500 =  26.5e18;
            // e.g. (new) amount = 1e19 * 950 / 500  =  19e17;
            uint256 amount = _amount.mul(reduction).div(totalCliffs);
            // e.g. amtTillMax = 5e25 - 1e25 = 4e25
            uint256 amtTillMax = EMISSIONS_MAX_SUPPLY.sub(emissionsMinted);
            if (amount > amtTillMax) {
                amount = amtTillMax;
            }
            _mint(_to, amount);
        }
    }

    /**
     * @dev Allows minter to mint to a specific address
     */
    function minterMint(address _to, uint256 _amount) external {
        require(msg.sender == minter || allowedMinters[msg.sender] == true, "Only minter");
        minterMinted += _amount;
        _mint(_to, _amount);
    }
}