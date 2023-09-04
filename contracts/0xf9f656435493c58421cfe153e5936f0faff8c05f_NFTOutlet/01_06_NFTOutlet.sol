// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { BillyTheBull } from "./BillyTheBull.sol";
import { ERC20 } from "@solmate/tokens/ERC20.sol";
import { IERC721 } from "./interfaces/IERC721.sol";

contract NFTOutlet {
    address immutable puzzle;

    ERC20 public paymentToken;
    IERC721 public nftDealOfTheDay;
    address treasury;

    mapping(address => bool) public validAssets;
    mapping(address => bool) public mintsClaimed;
    mapping(bytes32 => bool) public magicFlagsUsed;

    constructor(
        address _puzzle,
        address[] memory _paymentTokens,
        address[] memory _nfts
    ) {
        puzzle = _puzzle;
        paymentToken = ERC20(_paymentTokens[0]);
        nftDealOfTheDay = IERC721(_nfts[0]);

        for (uint256 i = 0; i < _paymentTokens.length; i++) {
            validAssets[_paymentTokens[i]] = true;
        }

        for (uint256 i = 0; i < _nfts.length; i++) {
            validAssets[_nfts[i]] = true;
        }
    }

    /////////////////////////
    /////// MODIFIERS ///////
    /////////////////////////

    modifier onlyPuzzle() {
        require(msg.sender == puzzle, "only puzzle");
        _;
    }

    modifier onlyPuzzleOwner() {
        require(msg.sender == BillyTheBull(puzzle).owner(), "only puzzle owner");
        _;
    }

    /////////////////////////
    //// PAYMENT ACTIONS ////
    /////////////////////////

    function pay(address _from, uint256 _amount) public onlyPuzzle returns (bool) {
        require(_from != address(0), "no zero address");
        try paymentToken.transferFrom(_from, address(this), _amount) returns (bool) {
            require(
                keccak256(abi.encode(_amount)) !=
                0x420badbabe420badbabe420badbabe420badbabe420badbabe420badbabe6969,
                "too immature"
            );
            return true;
        } catch {
            require(uint(uint32(_amount)) <= 4294967295, "invalid amount");
            return false;
        }
    }

    /////////////////////////
    //// MINTING ACTIONS ////
    /////////////////////////

    function mint(address _to, uint256 _tokenId) public onlyPuzzle returns (bool) {
        require(!mintsClaimed[_to], "already claimed");
        try nftDealOfTheDay.safeMint(_to, _tokenId) {
            mintsClaimed[_to] = true;
            return true;
        } catch {
            return false;
        }
    }

    /////////////////////////
    ///// ADMIN ACTIONS /////
    /////////////////////////

    function setMagicFlagUsed(bytes32 _magicFlag) onlyPuzzle public {
        magicFlagsUsed[_magicFlag] = true;
    }

    function changePaymentToken(address _newStablecoin) public onlyPuzzleOwner {
        require(validAssets[_newStablecoin], "no sneaky assets");
        paymentToken = ERC20(_newStablecoin);
    }

    function rescueERC20(address _token) public {
        ERC20(_token).transfer(treasury, ERC20(_token).balanceOf(address(this)));
    }
}