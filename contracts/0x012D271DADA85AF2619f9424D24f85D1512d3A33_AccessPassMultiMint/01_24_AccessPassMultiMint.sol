// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.8.6;

/**
* @title Helper Contract for AccessPassNFT to allow multi-minting
* @author MetaFrames
* @notice This is used in conjunction with the AccessPassNFT
*/

import "./AccessPassNFT.sol";
import "./WhitelistVerifier.sol";
import "./interfaces/IAccessPassNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract AccessPassMultiMint is Ownable, WhitelistVerifier, IERC721Receiver {

    /**
    * @dev accessPassNFT is the related AccessPassNFT to this contract
    */
    AccessPassNFT public accessPassNFT;

    /**
    * @dev multiMintVerifiedSlot is the signature needed for AccessPassMultiMint to privately mint
    */
    IAccessPassNFT.VerifiedSlot public multiMintVerifiedSlot;

    /**
    * @dev maxPublicMintable is the limit accounts can publically mint
    */
    uint256 public maxPublicMintable;

    /**
   * @dev multiMinted keeps track how many each address has minted of a certain minting type
    */
    mapping(AccessPassNFT => mapping(address => mapping(IAccessPassNFT.MintingType => uint256))) public multiMinted;

    /**
    * @dev emitted when a new AccessPassNFT is set
    * @param oldAccessPassNFT is the old accessPassNFT the contract was set to
    * @param newAccessPassNFT is the new accessPassNFT the contract has been set to
    */
    event AccessPassNFTSet(AccessPassNFT oldAccessPassNFT, AccessPassNFT newAccessPassNFT);

    /**
    * @dev emitted when a new VerifiedSlotSet is set
    * @param oldVerifiedSlot is the old verifiedSlot the contract was set to
    * @param newVerifiedSlot is the new verifiedSlot the contract has been set to
    */
    event VerifiedSlotSet(IAccessPassNFT.VerifiedSlot oldVerifiedSlot, IAccessPassNFT.VerifiedSlot newVerifiedSlot);

    /**
    * @dev emitted when a new maxPublicMintable is set
    * @param oldMaxPublicMintable is the old maxPublicMintable the contract was set to
    * @param newMaxPublicMintable is the new maxPublicMintable the contract has been set to
    */
    event MaxPublicMintableSet(uint256 oldMaxPublicMintable, uint256 newMaxPublicMintable);

    /**
    * @dev emitted when an account successfully multiMints
    * @param mintingType is the type of multiMint
    * @param minter is the address that multiMinted
    * @param nftsMinted is the amount of tokens minted in the multiMint
    */
    event MultiMinted(IAccessPassNFT.MintingType mintingType, address minter, uint256 nftsMinted);

    /**
    * @dev reverted with this error when a variable has an incorrect value
    * @param variableName is the name of the variable with an incorrect value
    */
    error IncorrectValue(string variableName);

    /**
    * @dev reverted with this error when a view function is asking for a Zero Address' information
    */
    error ZeroAddressQuery();

    /**
    * @notice initializes the contract
    * @param accessPassNFT_ is the address of the AccessPassNFT related to this contract
    */
    constructor(AccessPassNFT accessPassNFT_) {
        _setAccessPassNFT(accessPassNFT_);
        maxPublicMintable = 10;
    }

    /********************** EXTERNAL ********************************/

    /**
    * @notice multi private mints for people in the whitelist
    * @param verifiedSlot is a signed message by the whitelist signer that presents how many the minter can mint
    * @param nftsToMint is the amount of tokens the account wants to mint
    */
    function multiPrivateMint(IAccessPassNFT.VerifiedSlot calldata verifiedSlot, uint256 nftsToMint) external payable {
        uint256 totalMinted = totalMintedBy(msg.sender, IAccessPassNFT.MintingType.PRIVATE_MINT);

        validateVerifiedSlot(msg.sender, totalMinted, verifiedSlot);
        uint256 mintable = getMintable(nftsToMint, totalMinted, verifiedSlot.mintingCapacity);

        if(mintable == 0) revert IncorrectValue("nftsToMint");

        uint256 price = accessPassNFT.price();
        if(mintable * price != msg.value) revert IncorrectValue("msg.value");

        uint256 lastTokenId = accessPassNFT.totalSupply();

        multiMinted[accessPassNFT][msg.sender][IAccessPassNFT.MintingType.PRIVATE_MINT] += mintable;

        for(uint256 i = 0; i < mintable; i++) {
            accessPassNFT.privateMint{value: price}(multiMintVerifiedSlot);
            accessPassNFT.safeTransferFrom(address(this), msg.sender, lastTokenId++);
        }

        emit MultiMinted(IAccessPassNFT.MintingType.PRIVATE_MINT, msg.sender, mintable);
    }

    /**
    * @notice multi public mints for anyone up to the maxPublicMintable
    * @param nftsToMint is the amount of tokens the account wants to mint
    */
    function multiPublicMint(uint256 nftsToMint) external payable {
        uint256 totalMinted = totalMintedBy(msg.sender, IAccessPassNFT.MintingType.PUBLIC_MINT);
        uint256 mintable = getMintable(nftsToMint, totalMinted, maxPublicMintable);

        if(mintable == 0) revert IncorrectValue("nftsToMint");

        uint256 price = accessPassNFT.price();
        if(mintable * price != msg.value) revert IncorrectValue("msg.value");

        uint256 lastTokenId = accessPassNFT.totalSupply();

        multiMinted[accessPassNFT][msg.sender][IAccessPassNFT.MintingType.PUBLIC_MINT] += mintable;

        for(uint256 i = 0; i < mintable; i++) {
            accessPassNFT.publicMint{value: price}();
            accessPassNFT.safeTransferFrom(address(this), msg.sender, lastTokenId++);
        }

        emit MultiMinted(IAccessPassNFT.MintingType.PUBLIC_MINT, msg.sender, mintable);
    }

    /**
    * @notice sets the accessPassNFT
    * @param accessPassNFT_ is the AccessPassNFT related to this contract
    */
    function setAccessPassNFT(AccessPassNFT accessPassNFT_) external onlyOwner {
        _setAccessPassNFT(accessPassNFT_);
    }

    /**
    * @notice sets the verifiedSlot
    * @dev do this after setting the accessPassNFT if the contract status is still in PRIVATE_MINTING
    * @param verifiedSlot is a signed message by the whitelist signer that presents how many this contract can mint
    */
    function setVerifiedSlot(IAccessPassNFT.VerifiedSlot calldata verifiedSlot) external onlyOwner {
        validateVerifiedSlot(address(this), accessPassNFT.mintedBy(address(this)), verifiedSlot);
        emit VerifiedSlotSet(multiMintVerifiedSlot, verifiedSlot);
        multiMintVerifiedSlot = verifiedSlot;
    }

    /**
    * @notice synchronizes the whitelist signer to the accessPassNFT's whitelist signer
    * @dev do this after setting a new whitelist signer on the AccessPassNFT
    */
    function syncWhitelistSigner() external onlyOwner {
        _setWhiteListSigner(accessPassNFT.whiteListSigner());
    }

    /**
    * @notice sets how many the public can multi public mint through this contract
    * @param maxPublicMintable_ is the amount the public can multiMint for
    */
    function setMaxPublicMintable(uint256 maxPublicMintable_) external onlyOwner {
        emit MaxPublicMintableSet(maxPublicMintable, maxPublicMintable_);
        maxPublicMintable = maxPublicMintable_;
    }

    /********************** EXTERNAL VIEW ********************************/

    /**
    * @notice check if ERC721 received is from a multi mint
    * @inheritdoc IERC721Receiver
    */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external view override returns (bytes4) {
        // only allow nfts from multi mints of the accessPass
        if (operator == address(this) && msg.sender == address(accessPassNFT))
            return IERC721Receiver.onERC721Received.selector;
        else return bytes4(0);
    }

    /**
    * @notice returns how many an account can still private mint
    * @param verifiedSlot is a signed message by the whitelist signer that presents how many the minter can mint
    */
    function getMaxPrivateMintable(IAccessPassNFT.VerifiedSlot calldata verifiedSlot) external view returns(uint256) {
        if(verifiedSlot.minter == address(0)) revert ZeroAddressQuery();
        uint256 totalMinted = totalMintedBy(verifiedSlot.minter, IAccessPassNFT.MintingType.PRIVATE_MINT);

        validateVerifiedSlot(verifiedSlot.minter, totalMinted, verifiedSlot);
        return getMintable(verifiedSlot.mintingCapacity, totalMinted, verifiedSlot.mintingCapacity);
    }

    /**
    * @notice returns how many an account can still public mint
    * @param account is the address being queried for
    */
    function getMaxPublicMintable(address account) external view returns(uint256) {
        if(account == address(0)) revert ZeroAddressQuery();
        uint256 totalMinted = totalMintedBy(account, IAccessPassNFT.MintingType.PUBLIC_MINT);
        return getMintable(maxPublicMintable, totalMinted, maxPublicMintable);
    }

    /**
    * @notice returns how many an account has minted
    * @param account is the address being queried for
    */
    function totalMintedBy(address account) external view returns(uint256) {
        return
            totalMintedBy(account, IAccessPassNFT.MintingType.PRIVATE_MINT) +
            totalMintedBy(account, IAccessPassNFT.MintingType.PUBLIC_MINT);
    }

    /********************** PUBLIC ********************************/

    /**
    * @notice returns how many an account has minted per MintingType
    * @param account is the address being queried for
    * @param mintingType is split into PRIVATE_MINT and PUBLIC_MINT
    */
    function totalMintedBy(address account, IAccessPassNFT.MintingType mintingType) public view returns(uint256) {
        if(account == address(0)) revert ZeroAddressQuery();
        uint256 single = accessPassNFT.mintedBy(account, mintingType);
        uint256 multi = multiMinted[accessPassNFT][account][mintingType];
        return single + multi;
    }

    /********************** INTERNAL ********************************/

    /**
    * @notice sets the accessPassNFT and syncs the DOMAIN_SEPARATOR and whitelist signer
    * @param accessPassNFT_ is the AccessPassNFT related to this contract
    */
    function _setAccessPassNFT(AccessPassNFT accessPassNFT_) internal {
        bytes4 accessPassNFTInterfaceId = type(IAccessPassNFT).interfaceId;
        if (!accessPassNFT_.supportsInterface(accessPassNFTInterfaceId)) revert IncorrectValue("accessPassNFT_");

        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: "AccessPassNFT",
            version: '1',
            chainId: block.chainid,
            verifyingContract: address(accessPassNFT_)
        }));

        _setWhiteListSigner(accessPassNFT_.whiteListSigner());

        emit AccessPassNFTSet(accessPassNFT, accessPassNFT_);
        accessPassNFT = accessPassNFT_;
    }

    /**
    * @notice returns how many an account can mint
    * @param nftsToMint is the amount the account wants to mint
    * @param minted is the amount the account has multi and single minted
    * @param mintingCapacity is the maximum the account can mint
    */
    function getMintable(uint256 nftsToMint, uint256 minted, uint256 mintingCapacity) internal view returns(uint256) {
        // if owner changed the minting capacity to something lower than the account's minted count, it should return 0
        if(minted > mintingCapacity) return 0;
        if(mintingCapacity < nftsToMint + minted) nftsToMint = mintingCapacity - minted;

        uint256 totalSupply = accessPassNFT.totalSupply();
        uint256 maxTotalSupply = accessPassNFT.maxTotalSupply();

        if(maxTotalSupply < totalSupply + nftsToMint) nftsToMint = maxTotalSupply - totalSupply;
        return nftsToMint;
    }

}