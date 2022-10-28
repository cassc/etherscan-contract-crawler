// SPDX-License-Identifier: MIT

/// @title Halloween in Brooklyn by Joey L
/// @author transientlabs.xyz

pragma solidity 0.8.14;

import "ERC721ATLMerkle.sol";

interface TrickOrTreat {
    function mintExternal(uint256 tokenId, uint256 numToMint, address recipient) external;
}

contract HalloweenInBrooklyn is ERC721ATLMerkle {

    TrickOrTreat public trickOrTreat;
    uint256 public numberOfCostumes;
    mapping(uint256 => uint256) private _costumeAssignment;

    /**
    *   @param royaltyRecipient is the royalty recipient
    *   @param royaltyPercentage is the royalty percentage to set
    *   @param price is the mint price
    *   @param supply is the total token supply for minting
    *   @param merkleRoot is the allowlist merkle root
    *   @param admin is the admin address
    *   @param payout is the payout address
    *   @param numCostumes is the number of costumes
    */
    constructor(
        address royaltyRecipient,
        uint256 royaltyPercentage,
        uint256 price,
        uint256 supply,
        bytes32 merkleRoot,
        address admin,
        address payout,
        uint256 numCostumes
    )
    ERC721ATLMerkle(
        "Halloween in Brooklyn",
        "HALLOWEEN",
        royaltyRecipient,
        royaltyPercentage,
        price,
        supply,
        merkleRoot,
        admin,
        payout
    )
    {
        numberOfCostumes = numCostumes;
    }
    
    /// @notice function to set number of costumes
    /// @dev requires owner or admin
    function setNumberOfCostumes(uint256 numCostumes) external adminOrOwner {
        numberOfCostumes = numCostumes;
    }

    /// @notice function to set Trick or Treat address
    /// @dev requires owner or admin
    function setTrickOrTreat(address newAddress) external adminOrOwner {
        trickOrTreat = TrickOrTreat(newAddress);
    }

    /// @notice function to override mint function and disable
    function mint(uint256 numToMint, bytes32[] calldata merkleProof) external payable override nonReentrant {
        revert("disabled");
    }

    /// @notice new mint function to add in random costume assignment on mint
    /// @dev mints trick or treat house as well
    function mintToken(uint256 numToMint, bytes32[] calldata merkleProof, uint256 houseNumber) external payable nonReentrant {
        require(_totalMinted() + numToMint <= maxSupply, "No token supply left");
        require(msg.value >= mintPrice * numToMint, "Not enough ether attached to the transaction");
        require(_numberMinted(msg.sender) + numToMint <= mintAllowance, "Mint allowance reached");
        if (allowlistSaleOpen) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, allowlistMerkleRoot, leaf), "Not on allowlist");
        }
        else if (!publicSaleOpen) {
            revert("Mint not open");
        }

        uint256 tokenId = _nextTokenId();
        for (uint256 i = 0; i < numToMint; i++) {
            _costumeAssignment[tokenId + i] = tokenId + i;
        }

        trickOrTreat.mintExternal(houseNumber, numToMint, msg.sender);

        _safeMint(msg.sender, numToMint);
    }

    /// @notice function to set costume for a token
    /// @dev requires owner of the token to be the msg sender
    /// @dev need to refresh metadata after changing
    /// @param tokenId is the token to change costume for
    /// @param costume is the costume number
    function changeCostume(uint256 tokenId, uint256 costume) external {
        require(_exists(tokenId), "Invalid token id");
        require(msg.sender == ownerOf(tokenId), "Sender must be token owner");
        require(costume >= 1 && costume <= numberOfCostumes, "Invalid costume number sent");
        _costumeAssignment[tokenId] = costume;
    }

    /// @notice function to get current costume
    function getCostume(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "Query for non existent token");
        uint256 costume = _costumeAssignment[tokenId];
        if (costume == 0) {
            return 1;
        } else {
            return costume;
        }
    }

    /// @notice function to override tokenURI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        uint256 costume = _costumeAssignment[tokenId];
        if (costume == 0) {
            costume = 1;
        }
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, "/", _toString(tokenId), "/", _toString(costume))) : '';
    }
}