// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * アニメ メタバース 超新星
 * Anime Metaverse SUPERNOVA
 **/

///@author WhiteOakKong

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

interface IBurntSouls {
    function resurect(address to, uint256 tokenId) external;
}

contract SuperNova is ERC721A, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;
    using ECDSA for bytes32;

    // ============ 保管所 ============

    string public baseURI;

    IERC721 public immutable soulMates;
    IBurntSouls public immutable burntSouls;

    uint256 private constant LEGENDARY_COUNT = 28;

    bool public publicMinting;

    address private constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address private signer = 0x22F26B51dca5DF18549DC7E8C140153e6eb61980;
    address private relayer = 0xaEF8172c057f582dA82BF7CEc96F0e6706615b54;

    mapping(address => bool) private treasuryWallets;

    string private uriExtension = ".json";

    event Supernova(uint256 tokenId, uint256[] burntTokens, uint256 burntTotal, string character, uint256 hype);

    // ============ コンストラクタ ============

    constructor(address[] memory legendaryAddresses, address _burntSouls) ERC721A("Supernova", "AMSNOVA") {
        mintLegendary(legendaryAddresses);
        soulMates = IERC721(0x68Cd21D362C2DAe66909afD810e391fA152B2379);
        burntSouls = IBurntSouls(_burntSouls);
    }

    // ============ ミント関数 ============

    ///@notice Main function to mint a Supernova. Uses ECDSA to verify the mint details, and emits custom event for indexing.
    ///@param burntsouls - array of soulmate token ids
    ///@param character - character name: Rikka, Minami, Saki, Kyoko, Kumi, Male, or Random
    ///@param signature - signature for ECDSA recovery
    ///@param hype - quantity of hype from all burnt tokens
    function mintSupernova(
        uint256[] calldata burntsouls,
        bytes memory signature,
        string memory character,
        uint256 hype
    ) external {
        require(publicMinting, "Public minting is not enabled.");
        require(burntsouls.length > 0 && burntsouls.length < 6, "Invalid number of tokens");
        require(_isValidSignature(signature, burntsouls, character, hype), "Invalid signature");
        for (uint256 i = 0; i < burntsouls.length; i++) {
            soulMates.transferFrom(msg.sender, BURN_ADDRESS, burntsouls[i]);
            burntSouls.resurect(msg.sender, burntsouls[i]);
        }
        _mint(msg.sender, 1);
        emit Supernova(_totalMinted(), burntsouls, burntsouls.length, character, hype);
    }

    ///@notice Function to mint 1/1 Supernovas. These tokens are not mintable by the public, and are to be minted during contract deployment.
    ///@dev Mint all 28 Legendaries at once. All tokens mint sequentially, starting at 1. No event emission as these are preassigned. Mint during contract deployment.
    ///@param to - array of addresses to mint to
    function mintLegendary(address[] memory to) internal {
        require(_totalMinted() < LEGENDARY_COUNT, "No more legendary Supernovas left to mint.");
        for (uint256 i; i < to.length; i++) {
            _mint(to[i], 1);
        }
    }

    ///@notice Secondary function to allow minting of male tokens.
    ///@dev Only the registered relayer can use this function.
    ///@param recipient - address to mint token to.
    function mintMale(address recipient) external {
        require(msg.sender == relayer || msg.sender == owner(), "Only relayer/owner can mint");
        uint256[] memory emptyArray = new uint256[](0);
        _mint(recipient, 1);
        emit Supernova(_totalMinted(), emptyArray, 0, "Male", 0);
    }

    // ============ 効用 ============

    ///@notice Function to return tokenURI.
    ///@param _tokenId - tokenId to be returned.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), uriExtension));
    }

    ///@notice internal signature validation function.
    ///@param signature - signature for ECDSA recovery.
    ///@param burntTokens - array of soulmate token ids.
    ///@param character - character name: Rikka, Minami, Saki, Kyoko, Kumi, or Random
    ///@param hype - quantity of hype from all burnt tokens.
    function _isValidSignature(
        bytes memory signature,
        uint256[] calldata burntTokens,
        string memory character,
        uint256 hype
    ) internal view returns (bool) {
        bytes32 data = keccak256(abi.encodePacked(burntTokens, "_", character, "_", hype));
        return signer == data.toEthSignedMessageHash().recover(signature);
    }

    ///@notice Overriding the default tokenID start to 1.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // ============ 制限付きアクセス ============

    ///@notice Owner restricted function to mint a Supernova. Uses ECDSA to verify the mint details, and emits custom event for indexing.
    ///@dev Setting this up to allow early minting for the team.
    ///@param burntsouls - array of soulmate token ids
    ///@param character - character name: Rikka, Minami, Saki, Kyoko, Kumi, Male, or Random
    ///@param signature - signature for ECDSA recovery
    ///@param hype - quantity of hype from all burnt tokens
    function teamSupernovaMint(
        uint256[] calldata burntsouls,
        bytes memory signature,
        string memory character,
        uint256 hype
    ) external {
        require(treasuryWallets[msg.sender], "Only treasury wallets can mint");
        require(burntsouls.length > 0 && burntsouls.length < 6, "Invalid number of tokens");
        require(_isValidSignature(signature, burntsouls, character, hype), "Invalid signature");
        for (uint256 i = 0; i < burntsouls.length; i++) {
            soulMates.transferFrom(msg.sender, BURN_ADDRESS, burntsouls[i]);
            burntSouls.resurect(msg.sender, burntsouls[i]);
        }
        _mint(msg.sender, 1);
        emit Supernova(_totalMinted(), burntsouls, burntsouls.length, character, hype);
    }

    ///@notice Function to set the relayer address.
    ///@param _relayer - address of the relayer.
    function updateRelayer(address _relayer) external onlyOwner {
        require(_relayer != address(0), "Invalid address");
        relayer = _relayer;
    }

    ///@notice Function to set the signer address.
    ///@param _signer - address of the signer.
    function updateSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Invalid address");
        signer = _signer;
    }

    ///@notice Function to set the uri extension.
    ///@param _ext - uri extension.
    function updateExtension(string memory _ext) external onlyOwner {
        uriExtension = _ext;
    }

    ///@notice Function to set the baseURI for the contract.
    ///@param baseURI_ - baseURI for the contract.
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    ///@notice Function to toggle public minting of Supernovas.
    function togglePublic() external onlyOwner {
        publicMinting = !publicMinting;
    }

    ///@notice Function to add a treasury wallet. Access control for team mint.
    function addTreasuryWallet(address _wallet) external onlyOwner {
        treasuryWallets[_wallet] = true;
    }

    ///@notice Function to withdraw all funds from the contract. Should not be necessary, but just in case.
    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // ============ ファックオープンシー ============

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}