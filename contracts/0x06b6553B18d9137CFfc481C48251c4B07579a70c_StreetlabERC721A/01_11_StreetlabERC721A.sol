// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "erc721a/contracts/ERC721A.sol";

/// @title StreetlabERC721A
/// @author Julien Bessaguet
/// @notice NFT contracts for Streetlab OGs
contract StreetlabERC721A is ERC721A, Ownable {
    using ECDSA for bytes32;

    /// @notice Mint steps
    /// CLOSED sale closed or sold out
    /// GIVEAWAY Free mint opened
    /// ALLOWLIST Allow list sale
    /// WAITLIST Wait list list sale
    /// PUBLIC Public sale
    enum MintStep {
        CLOSED,
        GIVEAWAY,
        ALLOWLIST,
        WAITLIST,
        PUBLIC
    }

    event MintStepUpdated(MintStep step);

    uint256 public limitPerPublicMint = 2;

    uint256 public presalePrice;
    uint256 public publicPrice;
    /// @notice Revenues & Royalties recipient
    address public beneficiary;

    uint256 public giveaway;
    uint256 public immutable maxSupply;
    address public constant CROSSMINT_ADDRESS =
        0xdAb1a1854214684acE522439684a145E62505233;

    /// @notice used nonces
    mapping(uint256 => bool) internal _nonces;

    ///@notice Provenance hash of images
    string public provenanceHash;
    ///@notice Starting index, pseudo randomly set
    uint16 public startingIndex;

    /// @notice base URI for metadata
    string public baseURI;
    /// @dev Contract URI used by OpenSea to get contract details (owner, royalties...)
    string public contractURI;

    MintStep public step;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply_,
        uint256 giveaway_,
        uint256 presalePrice_,
        uint256 publicPrice_
    ) ERC721A(name, symbol) {
        beneficiary = owner();

        maxSupply = maxSupply_;
        giveaway = giveaway_;
        presalePrice = presalePrice_;
        publicPrice = publicPrice_;
    }

    modifier rightPresalePrice(uint256 quantity) {
        require(presalePrice * quantity == msg.value, "incorrect price");
        _;
    }

    modifier rightPublicPrice(uint256 quantity) {
        require(publicPrice * quantity == msg.value, "incorrect price");
        _;
    }

    modifier whenMintIsPublic() {
        require(step == MintStep.PUBLIC, "public sale is not live.");
        _;
    }

    modifier whenMintIsPresale() {
        MintStep step_ = step;
        require(
            step_ == MintStep.ALLOWLIST || step_ == MintStep.WAITLIST,
            "presale is not live."
        );
        _;
    }

    modifier whenMintIsNotClosed() {
        require(step != MintStep.CLOSED, "mint is closed");
        _;
    }

    modifier belowMaxAllowed(uint256 quantity, uint256 max) {
        require(quantity <= max, "quantity above max");
        _;
    }

    modifier belowTotalSupply(uint256 quantity) {
        require(
            totalSupply() + quantity <= maxSupply - giveaway,
            "not enough tokens left."
        );
        _;
    }

    modifier belowPublicLimit(uint256 quantity) {
        require(quantity <= limitPerPublicMint, "limitPerPublicMint exceeded!");
        _;
    }

    /// @notice Mint your NFT(s) (public sale)
    /// @param quantity number of NFT to mint
    /// no gift allowed nor minting from other smartcontracts
    function mint(uint256 quantity)
        external
        payable
        whenMintIsPublic
        rightPublicPrice(quantity)
        belowTotalSupply(quantity)
        belowPublicLimit(quantity)
    {
        _safeMint(msg.sender, quantity);
    }

    /// @notice Mint NFT(s) by Credit Card with Crossmint (public sale)
    /// @param to NFT recipient
    /// @param quantity number of NFT to mint
    function mintTo(address to, uint256 quantity)
        external
        payable
        whenMintIsPublic
        rightPublicPrice(quantity)
        belowTotalSupply(quantity)
        belowPublicLimit(quantity)
    {
        require(msg.sender == CROSSMINT_ADDRESS, "for crossmint only.");
        _safeMint(to, quantity);
    }

    /// @notice Mint NFT(s) during allowlist/waitlist sale
    /// Can only be done once.
    /// @param quantity number of NFT to mint
    /// @param max Max number of token allowed to mint
    /// @param nonce Random number providing a mint spot
    /// @param sig ECDSA signature allowing the mint
    function mintPresale(
        uint256 quantity,
        uint256 max,
        uint256 nonce,
        bytes memory sig
    )
        external
        payable
        whenMintIsPresale
        rightPresalePrice(quantity)
        belowTotalSupply(quantity)
        belowMaxAllowed(quantity, max)
    {
        string memory phase = step == MintStep.ALLOWLIST
            ? "allowlist"
            : "waitlist";
        require(!_nonces[nonce], "presale nonce already used.");
        _nonces[nonce] = true;
        _validateSig(phase, msg.sender, max, nonce, sig);

        _safeMint(msg.sender, quantity);
    }

    /// @notice Mint NFT(s) during allowlist/waitlist sale
    /// along with giveaway to save gas.
    /// Can only be done once.
    /// @param quantityGiveaway number of giveaway NFT to mint
    /// @param nonceGiveaway Random number providing a mint spot
    /// @param quantityPresale number of presale NFT to mint
    /// @param maxPresale Max number of token allowed to mint
    /// @param noncePresale Random number providing a mint spot
    /// @param sigGiveaway ECDSA signature allowing the mint
    /// @param sigPresale ECDSA signature allowing the mint
    function mintPresaleWithGiveaway(
        uint256 quantityGiveaway,
        uint256 nonceGiveaway,
        uint256 quantityPresale,
        uint256 maxPresale,
        uint256 noncePresale,
        bytes memory sigGiveaway,
        bytes memory sigPresale
    ) external payable whenMintIsPresale {
        if (quantityPresale > 0) {
            require(quantityPresale <= maxPresale, "quantity above max");
            require(!_nonces[noncePresale], "presale nonce already used.");
            require(
                totalSupply() + quantityPresale <= maxSupply - giveaway,
                "not enough tokens left."
            );
            require(
                quantityPresale * presalePrice <= msg.value,
                "incorrect price"
            );
            _nonces[noncePresale] = true;
            string memory phase = step == MintStep.ALLOWLIST
                ? "allowlist"
                : "waitlist";
            _validateSig(
                phase,
                msg.sender,
                maxPresale,
                noncePresale,
                sigPresale
            );
        }
        if (quantityGiveaway > 0) {
            require(!_nonces[nonceGiveaway], "giveaway nonce already used.");
            uint256 giveaway_ = giveaway;
            require(
                quantityGiveaway <= giveaway_,
                "cannot exceed max giveaway."
            );
            _nonces[nonceGiveaway] = true;
            giveaway = giveaway_ - quantityGiveaway;
            _validateSig(
                "giveaway",
                msg.sender,
                quantityGiveaway,
                nonceGiveaway,
                sigGiveaway
            );
        }

        _safeMint(msg.sender, quantityGiveaway + quantityPresale);
    }

    /// @notice Mint NFT(s) during public sale
    /// along with giveaway to save gas.
    /// Can only be done once.
    /// @param quantityPublic number of public NFT to mint
    /// @param quantityGiveaway number of giveaway NFT to mint
    /// @param nonceGiveaway Random number providing a mint spot
    /// @param sigGiveaway ECDSA signature allowing the mint
    function mintWithGiveaway(
        uint256 quantityPublic,
        uint256 quantityGiveaway,
        uint256 nonceGiveaway,
        bytes memory sigGiveaway
    )
        external
        payable
        whenMintIsPublic
        rightPublicPrice(quantityPublic)
        belowTotalSupply(quantityPublic)
        belowPublicLimit(quantityPublic)
    {
        if (quantityGiveaway > 0) {
            require(!_nonces[nonceGiveaway], "giveaway nonce already used.");
            uint256 giveaway_ = giveaway;
            require(
                quantityGiveaway <= giveaway_,
                "cannot exceed max giveaway."
            );
            _nonces[nonceGiveaway] = true;
            giveaway = giveaway_ - quantityGiveaway;
            _validateSig(
                "giveaway",
                msg.sender,
                quantityGiveaway,
                nonceGiveaway,
                sigGiveaway
            );
        }

        _safeMint(msg.sender, quantityGiveaway + quantityPublic);
    }

    /// @notice Mint giveaway NFT(s) during any sale phase
    /// Can only be done once.
    /// @param quantity number of giveaway NFT to mint
    /// @param nonce Random number providing a mint spot
    /// @param sig ECDSA signature allowing the mint
    function mintGiveaway(
        uint256 quantity,
        uint256 nonce,
        bytes memory sig
    ) external whenMintIsNotClosed {
        require(!_nonces[nonce], "giveaway nonce already used.");
        uint256 giveaway_ = giveaway;
        require(quantity <= giveaway_, "cannot exceed max giveaway.");
        _nonces[nonce] = true;
        giveaway = giveaway_ - quantity;
        _validateSig("giveaway", msg.sender, quantity, nonce, sig);

        _safeMint(msg.sender, quantity);
    }

    /// @inheritdoc ERC721A
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @inheritdoc ERC721A
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @dev Setting starting index only once
    function _setStartingIndex() internal {
        if (startingIndex == 0) {
            uint256 predictableRandom = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        block.difficulty,
                        totalSupply()
                    )
                )
            );
            startingIndex = uint16(predictableRandom % (maxSupply));
        }
    }

    /// @dev Validating ECDSA signatures
    function _validateSig(
        string memory phase,
        address sender,
        uint256 amount,
        uint256 nonce,
        bytes memory sig
    ) internal view {
        bytes32 hash = keccak256(
            abi.encode(phase, sender, amount, nonce, address(this))
        );
        address signer = hash.toEthSignedMessageHash().recover(sig);
        require(signer == owner(), "invalid signature");
    }

    /// @notice Check whether nonce was used
    /// @param nonce value to be checked
    function validNonce(uint256 nonce) external view returns (bool) {
        return !_nonces[nonce];
    }

    /// @inheritdoc ERC721A
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == this.royaltyInfo.selector ||
            super.supportsInterface(interfaceId);
    }

    ////////////////////////////////////////////////////
    ///// Royalties                                   //
    ////////////////////////////////////////////////////

    /// @dev Royalties are the same for every token that's why we don't use OZ's impl.
    function royaltyInfo(uint256, uint256 amount)
        public
        view
        returns (address, uint256)
    {
        // (royaltiesRecipient || owner), 7.5%
        return (beneficiary, (amount * 750) / 10000);
    }

    ////////////////////////////////////////////////////
    ///// Only Owner                                  //
    ////////////////////////////////////////////////////

    /// @notice Gift a NFT to someone i.e. a team member, only done by owner
    /// @param to recipient address
    /// @param quantity number of NFT to mint and gift
    function gift(address to, uint256 quantity) external onlyOwner {
        uint256 giveaway_ = giveaway;
        require(quantity <= giveaway_, "cannot exceed max giveaway.");
        giveaway = giveaway_ - quantity;
        _safeMint(to, quantity);
    }

    /// @notice Allow the owner to change the baseURI
    /// @param newBaseURI the new uri
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /// @notice Allow the owner to set the provenancehash
    /// Should be set before sales open.
    /// @param provenanceHash_ the new hash
    function setProvenanceHash(string memory provenanceHash_)
        external
        onlyOwner
    {
        provenanceHash = provenanceHash_;
    }

    /// @notice Allow owner to set the royalties recipient
    /// @param newBeneficiary the new contract uri
    function setBeneficiary(address newBeneficiary) external onlyOwner {
        require(newBeneficiary != address(0), 'cannot set null address as beneficiary.');
        beneficiary = newBeneficiary;
    }

    /// @notice Allow owner to set contract URI
    /// @param newContractURI the new contract URI
    function setContractURI(string calldata newContractURI) external onlyOwner {
        contractURI = newContractURI;
    }

    /// @notice Allow owner to change minting step
    /// @param newStep the new step
    function setStep(MintStep newStep) external onlyOwner {
        step = newStep;
        // Set starting index after people minted
        _setStartingIndex();
        emit MintStepUpdated(newStep);
    }

    /// @notice Allow owner to update the limit per wallet for public mint
    /// @param newLimit the new limit e.g. 7 for public mint per wallet
    function setLimitPerPublicMint(uint256 newLimit) external onlyOwner {
        limitPerPublicMint = newLimit;
    }

    /// @notice Allow owner to update price for public mint
    /// @param newPrice the new price for public mint
    function setPublicPrice(uint256 newPrice) external onlyOwner {
        publicPrice = newPrice;
    }

    /// @notice Allow owner to update price for presale mint
    /// @param newPrice the new price for presale mint
    function setPresalePrice(uint256 newPrice) external onlyOwner {
        presalePrice = newPrice;
    }

    /// @notice Allow everyone to withdraw contract balance and send it to owner
    function withdraw() external {
        Address.sendValue(payable(beneficiary), address(this).balance);
    }

    /// @notice Allow everyone to withdraw contract ERC20 balance and send it to owner
    function withdrawERC20(IERC20 token) external {
        SafeERC20.safeTransfer(
            token,
            beneficiary,
            token.balanceOf(address(this))
        );
    }
}