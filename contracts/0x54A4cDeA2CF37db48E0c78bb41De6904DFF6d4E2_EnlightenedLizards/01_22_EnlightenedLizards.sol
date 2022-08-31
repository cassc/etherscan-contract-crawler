// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./QuantegyLabsAccessControl.sol";
import "./IClaimCenter.sol";
import "./IRightsProtocol.sol";

// The Lizards would be saved, he said, if they could be enlightened...
contract EnlightenedLizards is ERC721AQueryable, QuantegyLabsAccessControl {
    using Strings for uint256;
    using SafeMath for uint256;
		using Counters for Counters.Counter;
		Counters.Counter private _tokenIdCounter;

		// Whitelisting
    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;
    bool public whitelistMintEnabled = false;

		// Token Metadata
    string public uriPrefix = ""; // IPFS directory containing all NFT metadata files
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;
		string public hiddenRightsUri = "Rights URIs are hidden until reveal";

    // Minting tokens
		uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;

		// Collection status
    bool public paused = true;
    bool public revealed = false;

		// IP & rights for digital collectibles by MINTangible
    address payable private _rightsFeeRecipient;
    address private _rightsProtocolAddress;

		// Claim center management for token redeemables
		address public claimCenterAddress;
		IClaimCenter private _claimCenter;


    /// Events
    ////////////////////////////////////
    /// @dev Emitted when a new token is minted
    event NewLizardMinted(uint256 tokenId, string tokenURI, address phan);
    /// @dev Emitted when the contract owner withdraws the contract funds out to the treasury
    event FundsWithdrawn(uint256 balance);


    /// Modifiers
    ////////////////////////////////////
    modifier mintQtyCompliance(uint256 _mintAmount) {
			require(
				_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
				"Invalid mint amount!"
			);
			require(
				totalSupply() + _mintAmount <= maxSupply,
				"Max supply exceeded!"
			);
			_;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
			require(msg.value >= cost * _mintAmount, "Insufficient funds!");
			_;
    }

    constructor(
			string memory _tokenName,
			string memory _tokenSymbol,
			uint256 _cost,
			uint256 _maxSupply,
			uint256 _maxMintAmountPerTx,
			string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
			setCost(_cost);
			maxSupply = _maxSupply;
			setMaxMintAmountPerTx(_maxMintAmountPerTx);
			setHiddenMetadataUri(_hiddenMetadataUri);
    }


    /// Overrides
		/// https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol
    ////////////////////////////////////
    function _baseURI() internal view virtual override returns (string memory) {
			return uriPrefix;
    }

		/// @dev Start our token counting for this collection at 1 rather than 0
    function _startTokenId() internal view virtual override returns (uint256) {
			return 1;
    }

		/// @dev This stitches togther bits of dynamic data to a singular string
		/// @return // ipfs://[CID]/[tokenId].json or "" as a fallback
    function tokenURI(uint256 _tokenId)
			public
			view
			virtual
			override
			returns (string memory)
    {
			require(
				_exists(_tokenId),
				"ERC721Metadata: URI query for nonexistent token"
			);

			if (revealed == false) {
				return hiddenMetadataUri;
			}

			string memory currentBaseURI = _baseURI();
			return
				bytes(currentBaseURI).length > 0
					? string(
						abi.encodePacked(
							currentBaseURI,
							_tokenId.toString(),
							uriSuffix
						)
					)
					: "";
    }


		/// Methods
    ////////////////////////////////////
    function whitelistMintLizard(
        address _phan,
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    )
        public
        payable
        mintQtyCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        // Verify whitelist requirements
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(!whitelistClaimed[_msgSender()], "Address already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

				// Local tokenID tracking, incrementing
				_tokenIdCounter.increment();
				uint256 newLizardId = _tokenIdCounter.current();

				// Mint the given quantity for a singular tx
        _safeMint(_phan, _mintAmount);

        // Mark the minter as having claimed
        whitelistClaimed[_phan] = true;

        // Send digital collectible rights fee
        uint256 _rightsFeeValue = cost.mul(33).div(1000);
        Address.sendValue(_rightsFeeRecipient, _rightsFeeValue);

				// Emit event with new metadata url
        string memory newTokenURI = tokenURI(newLizardId);
        emit NewLizardMinted(newLizardId, newTokenURI, _phan);
    }

    function mintLizard(address _phan, uint256 _mintAmount)
        public
        payable
        mintQtyCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
			require(!paused, "The contract is paused!");

			// Local tokenID tracking, incrementing
			_tokenIdCounter.increment();
			uint256 newLizardId = _tokenIdCounter.current();

			// Mint the given quantity for a singular tx
			_safeMint(_phan, _mintAmount);

			// Send digital collectible rights fee
			uint256 _rightsFeeValue = cost.mul(33).div(1000);
			Address.sendValue(_rightsFeeRecipient, _rightsFeeValue);

			// Emit event with new metadata url
			string memory newTokenURI = tokenURI(newLizardId);
			emit NewLizardMinted(newLizardId, newTokenURI, _phan);
    }

    /// @dev Gets the given Digital IP Rights & Licensing URI from MINTangible for the given token ID
		/// Only shows the rights URIs post-reveal, as one could find image referneces in the rights metadata
    function rightsURIs(uint256 _tokenId)
        public
        view
        returns (string[] memory tokenRightsUris)
    {
			if (revealed == true) {
				return
					IRightsProtocol(_rightsProtocolAddress).rightsURIs(
							address(this),
							_tokenId
					);
			}

			return tokenRightsUris;
    }


    /// Owner Methods
    // ////////////////////////////////////
		/// @dev Mint a token for free on behalf of, this could be useful for airdropping, minting for free
    function adminMintLizard(address _receiver, uint256 _mintAmount)
        public
        mintQtyCompliance(_mintAmount)
        adminOnly
    {
			// Local tokenID tracking, incrementing
			_tokenIdCounter.increment();
			uint256 newLizardId = _tokenIdCounter.current();

			_safeMint(_receiver, _mintAmount);

				// Emit event with new metadata url
			string memory newTokenURI = tokenURI(newLizardId);
			emit NewLizardMinted(newLizardId, newTokenURI, _receiver);
    }

    function setPaused(bool _state) public onlyCTO {
        paused = _state;
    }

    function setRevealed(bool _state) public onlyCTO {
        revealed = _state;
    }

    function setCost(uint256 _cost) public adminOnly {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyCTO
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setWhitelistMintEnabled(bool _state) public onlyCTO {
        whitelistMintEnabled = _state;
    }

		function setMerkleRoot(bytes32 _merkleRoot) public onlyCTO {
        merkleRoot = _merkleRoot;
    }

		function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyCTO
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyCTO {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyCTO {
        uriSuffix = _uriSuffix;
    }


		/// Digital Rights
		////////////////////////////////////
    function setRightsFeeRecipient(address payable rightsFeeRecipient_) public onlyCTO {
        _rightsFeeRecipient = rightsFeeRecipient_;
    }

    function setRightsProtocolAddress(address rightsProtocolAddress_)
        public
        onlyCTO
    {
        _rightsProtocolAddress = rightsProtocolAddress_;
    }

		function rightsProtocolAddress() public view onlyCTO returns (address) {
			return _rightsProtocolAddress;
		}


		/// Claim Center
		////////////////////////////////////
		/// @dev Sets the claim center address that manages the collection's redeemable items
    function setClaimCenterAddress(address _claimCenterAddress) public onlyCTO
    {
			claimCenterAddress = _claimCenterAddress;
		}

		/// @dev Gets the redeemable items relating to the given token ID, as managed by the claim center
		function tokenRedeemables(uint256 _tokenId) public view returns (RedeemableItem[] memory redeemableItems)
		{
			if (claimCenterAddress == address(0)) return redeemableItems;
			return IClaimCenter(claimCenterAddress).getTokenRedeemables(address(this), _tokenId);
		}

    /// @dev Withdraw all the fund from the contract balance out to the Quantegy Labs treasury
    function fundTreasury() public onlyCEO nonReentrant {
        uint256 balance = address(this).balance;
				Address.sendValue(treasury, balance);
				// Emit the event
        emit FundsWithdrawn(balance);
    }
}