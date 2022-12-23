//
//  ██    ██ ██       █████  ███    ██ ██████       ██  ██████
//  ██    ██ ██      ██   ██ ████   ██ ██   ██      ██ ██    ██
//  ██    ██ ██      ███████ ██ ██  ██ ██   ██      ██ ██    ██
//  ██    ██ ██      ██   ██ ██  ██ ██ ██   ██      ██ ██    ██
//   ██████  ███████ ██   ██ ██   ████ ██████   ██  ██  ██████
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// @title ULAND Heroes dApp / uland.io
// @author [email protected]
// @whitepaper https://uland.io/Whitepaper.pdf
// @url https://heroes.uland.io/

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol"; //DEBUG ONLY

/**
 * @dev Uland NFT Interface
 */
interface IULANDHeroesNFT {
    function mint(uint256 tokenId, address to) external;
}

contract ULANDHeroesDapp is Ownable {
    using ECDSA for bytes32;
    using SafeMath for uint256;

    bool public paused = false;
    
    mapping(string => bool) public _usedNonces;

    uint256 public nextTokenId; // Counter to keep track of the next token ID to use

    IULANDHeroesNFT public _ulandHeroNFT;
    address public marketingWallet = 0x3B3E40522ba700a0c2E9030431E5e7fD9af28775; // $ULAND Marketing wallet
    
    address public signerAddress;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused,"PAUSED");
        _;
    }

    constructor(address _ulandHeroesNFTAddress, address _signerAddress) {
        _ulandHeroNFT = IULANDHeroesNFT(_ulandHeroesNFTAddress);
        signerAddress = _signerAddress;
        nextTokenId = 1;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public pure returns (string memory) {
        return "ULAND HEROES DAPP";
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public pure returns (string memory) {
        return "UHD";
    }

    /**
     * @dev Pre-pay for heroes
     */
    function pay(
        uint256 amount,
        uint256 validTo,
        string memory nonce,
        bytes32 hash,
        bytes memory signature
    ) external payable whenNotPaused {
        require(!_usedNonces[nonce], "NONCE REUSED");
        require(block.timestamp <= validTo, "EXPIRED");
        require(msg.value >= amount, "AMOUNT_TOO_LOW"); // Bid amount too low

        bytes32 _hash = keccak256(
            abi.encodePacked(amount, validTo, msg.sender, nonce)
        );
        require(_hash == hash, "INVALID HASH");
        require(matchSigner(hash, signature) == true, "INVALID SIG");

        _usedNonces[nonce] = true;
        // payable(owner()).transfer(msg.value);
        emit Pay(msg.sender, nonce, amount);
    }
    

    /**
     * @dev Validate signature
     */
    function matchSigner(bytes32 hash, bytes memory signature)
        public
        view
        returns (bool)
    {
        return
            signerAddress == hash.toEthSignedMessageHash().recover(signature);
    }

    /**
     * @dev Crate hash of bytes32
     */
    function hashTransaction(
        address sender,
        uint256 qty,
        string memory nonce
    ) public pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                sender,
                qty,
                nonce /*, address(this)*/
            )
        );
        return hash;
    }

    /**
     * @dev Withdraw funds to treasury
     */
    function treasuryWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /*
	 * onlyOwner functions
	 */

	function setSignerAddress(address _signerAddress) public onlyOwner {
		signerAddress = _signerAddress;
	}

    function setNFTAddress(address _nftAddress) public onlyOwner {
		_ulandHeroNFT = IULANDHeroesNFT(_nftAddress);
	}

    function setPause(bool _paused) public onlyOwner {
		paused = _paused;
	}

    function setMarketingWallet(address _marketingWallet) public onlyOwner {
		marketingWallet = _marketingWallet;
	}

    /*
	 * Events
	 */

    event Pay(address sender, string trxid, uint256 amount);
}