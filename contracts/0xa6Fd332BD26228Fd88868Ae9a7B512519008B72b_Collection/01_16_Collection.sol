// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./utils/Base64.sol";
import "./utils/MerkleProof.sol";

import "./CollectionDescriptor.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract Collection is ERC721 {

    address public owner = 0xaF69610ea9ddc95883f97a6a3171d52165b69B03; // for opensea integration. doesn't do anything else.
    address payable public recipient; // in this instance, it will be a 0xSplit on mainnet

    CollectionDescriptor public descriptor;

    // minting time
    uint256 public startDate;
    uint256 public endDate;

    mapping(uint256 => bool) randomMints;

    // for loyal mints
    mapping (address => bool) public claimed;
    bytes32 public loyaltyRoot;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_, address payable recipient_, uint256 startDate_, uint256 endDate_, bytes32 root_) ERC721(name_, symbol_) {
        descriptor = new CollectionDescriptor();
        recipient = recipient_;
        startDate = startDate_;
        endDate = endDate_;
        loyaltyRoot = root_;

        // mint #1 to UF to kickstart it. this is from the loyal mint so also set claim to true.
        // a random mint
        _createNFT(owner, block.timestamp, true);
        claimed[owner] = true;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory name = descriptor.generateName(tokenId); 
        string memory description = "Capsules containing visualizations of all the lives lived by simulated minds in the school of unlearning.";

        string memory image = generateBase64Image(tokenId);
        string memory attributes = generateTraits(tokenId);
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', 
                            name,
                            '", "description":"', 
                            description,
                            '", "image": "', 
                            'data:image/svg+xml;base64,', 
                            image,'",',
                            attributes,
                            '}'
                        )
                    )
                )
            )
        );
    }

    function generateBase64Image(uint256 tokenId) public view returns (string memory) {
        bytes memory img = bytes(generateImage(tokenId));
        return Base64.encode(img);
    }

    /*
    NOTE: Calling this when the token doesn't exist will result in it being defined
    as a "chosen seed" because randomMint will be 0 (or false) if it's not initialized.
    */
    function generateImage(uint256 tokenId) public view returns (string memory) {
        bool randomMint = randomMints[tokenId];
        return descriptor.generateImage(tokenId, randomMint);
    }

    function generateTraits(uint256 tokenId) public view returns (string memory) {
        bool randomMint = randomMints[tokenId];
        return descriptor.generateTraits(tokenId, randomMint);
    }

    /*
    VM Viewers:
    These drawing functions are used inside the browser vm to display the capsule without having to call a live network.
    */

    // Generally used inside the browser VM to preview a capsule for seed mints
    function generateImageFromSeedAndAddress(uint256 _seed, address _owner) public view returns (string memory) {
        uint256 tokenId = uint(keccak256(abi.encodePacked(_seed, _owner)));
        return generateImage(tokenId);
    }

    // a forced random mint viewer, used when viewing in the browser vm after a successful random mint
    function generateRandomMintImageFromTokenID(uint256 tokenId) public view returns (string memory) {
        return descriptor.generateImage(tokenId, true);
    }

    /* PUBLIC MINT OPTIONS */
    function mintWithSeed(uint256 _seed) public payable {
        require(msg.value >= 0.074 ether, "MORE ETH NEEDED"); // ~$100
        _mint(msg.sender, _seed, false);
    }

    function mint() public payable {
        require(msg.value >= 0.022 ether, "MORE ETH NEEDED"); // ~$30
        _mint(msg.sender, block.timestamp, true);
    }

    function loyalMint(bytes32[] calldata proof) public {
        loyalMintLeaf(proof, msg.sender);
    }

    // anyone can mint for someone in the merkle tree
    // you just need the correct proof
    function loyalMintLeaf(bytes32[] calldata proof, address leaf) public {
        // if one of addresses in the overlap set
        require(claimed[leaf] == false, "Already claimed");
        claimed[leaf] = true;

        bytes32 hashedLeaf = keccak256(abi.encodePacked(leaf));
        require(MerkleProof.verify(proof, loyaltyRoot, hashedLeaf), "Invalid Proof");
        _mint(leaf, block.timestamp, true); // mint a random mint for loyal collector
    }

    // FOR TESTING: UNCOMMENT TO RUN TESTS
    // For testing, we need to able to generate a specific random capsule.
    /*function mintWithSeedForcedRandom(uint256 _seed) public payable {
        require(msg.value >= 0.074 ether, "MORE ETH NEEDED"); // $100
        _mint(msg.sender, _seed, true);
    }*/

    /* INTERNAL MINT FUNCTIONS */
    function _mint(address _owner, uint256 _seed, bool _randomMint) internal {
        require(block.timestamp > startDate, "NOT_STARTED"); // ~ 2000 gas
        require(block.timestamp < endDate, "ENDED");
        _createNFT(_owner, _seed, _randomMint);
    }

    function _createNFT(address _owner, uint256 _seed, bool _randomMint) internal {
        uint256 tokenId = uint(keccak256(abi.encodePacked(_seed, _owner)));
        if(_randomMint) { randomMints[tokenId] = _randomMint; }
        super._mint(_owner, tokenId);
    }

    // WITHDRAWING ETH
    function withdrawETH() public {
        recipient.call{value: address(this).balance}(""); // this is safe because the recipient is known
    }
}