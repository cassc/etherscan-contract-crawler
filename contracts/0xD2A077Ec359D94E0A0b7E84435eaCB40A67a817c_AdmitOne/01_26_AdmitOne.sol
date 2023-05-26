// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "@divergencetech/ethier/contracts/crypto/SignatureChecker.sol";
import "@divergencetech/ethier/contracts/crypto/SignerManager.sol";
import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721ACommon.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++%%%%%%%%%%%%%%%%%%%%%%%%%%*+++++++++++++++++++++++++++++++++
[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@#+++++++++++++++++++++++++++++++++
++++++++++++++++++++++++++#%%%##########################%%%%*+++++++++++++++++++++++++++++
++++++++++++++++++++++++++%@@@*#########################%@@@*+++++++++++++++++++++++++++++
++++++++++++++++++++++*%%%##################################%%%#++++++++++++++++++++++++++
++++++++++++++++++++++#@@@##################################@@@%++++++++++++++++++++++++++
++++++++++++++++++*@@@%####%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%##%###%@@@%++++++++++++++++++++++
++++++++++++++++++*@@@@#%#######%######%######%%#######%#######%@@@%++++++++++++++++++++++
++++++++++++++++++*@@@@#%#####%#######%#%####%##%##############%@@@%++++++++++++++++++++++
++++++++++++++++++*@@@%%%%########***#####***####***#####***#%%%@@@#++++++++++++++++++++++
++++++++++++++++++++++#@@@@%%%[email protected]@@%++++++++++++++++++++++++++
++++++++++++++++++++++#@@@@%%%++++*******+++++++++++********@@@%++++++++++++++++++++++++++
++++++++++++++++++++++#@@@@%%%+++*********++++++++++********@@@%++++++++++++++++++++++++++
++++++++++++++++++*###%@@@%%%%+++*%%%#++++++++++++++*%%%*[email protected]@@%++++++++++++++++++++++++++
++++++++++++++++++*@@@@%%%%%%%+++*@@@%===+++++++++++#@@@*===%@@%++++++++++++++++++++++++++
++++++++++++++++++*@@@@%%%%%%%+++*###*++++++++++++++*###*+++%@@%++++++++++++++++++++++++++
++++++++++++++++++*@@@@%%%%%%%[email protected]@@%++++++++++++++++++++++++++
++++++++++++++++++*@@@@@@@@%%%[email protected]@@%++++++++++++++++++++++++++
++++++++++++++++++*@@@@@@@@%%%[email protected]@@%++++++++++++++++++++++++++
+++++++++++++++++++***#@@@@%%%%%%#+++++++%%%%++++%%%#[email protected]@@%++++++++++++++++++++++++++
++++++++++++++++++++++#@@@@%%%%%%%+++++++%@@@[email protected]@@#[email protected]@@%++++++++++++++++++++++++++
++++++++++++++++++++++#@@@@%%%%%%%%%%#+++****++++****+++#%%%@@@%++++++++++++++++++++++++++
++++++++++++++++++++++#@@@@%%%%%%%%%%#++++++++++++++++++#%%%@@@%++++++++++++++++++++++++++
++++++++++++++++++++++#@@@@%%%%%%%[email protected]@@%++++++++++++++++++++++++++
++++++++++++++++++++++#@@@@%%%%%@%+++********************[email protected]@@%++++++++++++++++++++++++++
++++++++++++++++++++++#@@@@%%%@@@@+++*@@@@@@@@@@@@@@@@@@#[email protected]@@%++++++++++++++++++++++++++
++++++++++++++++++++++#@@@@%%%@@@@+++*%%%%%%%%%%%%%%%%%%*[email protected]@@%++++++++++++++++++++++++++
++++++++++++++++++++++#@@@@%%%@@@@[email protected]@@%++++++++++++++++++++++++++
++++++++++++++++++++++#@@@@%%%@@@%####++++++++++++++++++*#######++++++++++++++++++++++++++
++++++++++++++++++++++#@@@@%%%%%%%@@@%++++++++++++++++++%@@@*+++++++++++++++++++++++++++++
++++++++++++++++++++++#@@@@%%%%%%%@@@%%%%%%%%%%%%%%%%%%%####*+++++++++++++++++++++++++++++
++++++++++++++++++++++#@@@@%%%%%%%%%%%@@@@@@@@@@@@@@@@@@#+++++++++++++++++++++++++++++++++
++++++++++++++++++++++#@@@@%%%%%%%%%%%@@@#***************+++++++++++++++++++++++++++++++++
++++++++++++++++++++++#@@@@%%%%%%%%%%%@@@*++++++++++++++++++++++++++++++++++++++++++++++++
++++++++++++++++++++++#@@@@%%%%%%%%%%%@@@*++++++++++++++++++++++++++++++++++++++++++++++++
++++++++++++++++++++++#@@@@%%%%%%%%%%%@@@*++++++++++++++++++++++++++++++++++++++++++++++++
*/

interface ITokenURIGenerator {
    function tokenURI(uint256) external view returns (string memory);
}

/**
@title Admit One
@author divergence.xyz
 */
contract AdmitOne is ERC721ACommon, BaseTokenURI, SignerManager, ERC2981 {
    using SignatureChecker for EnumerableSet.AddressSet;

    constructor(string memory name, string memory symbol)
        ERC721ACommon(name, symbol)
        BaseTokenURI("")
    {
        ERC2981._setDefaultRoyalty(
            0x38474Cf247b0B31d602d49ba8c227198EA2A7C7f,
            1000
        );
    }

    /**
    @dev Override ERC721A's initial token index.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
    @dev Max tokens issued by the contract.
     */
    uint256 public constant MAX_TOKENS = 1000;

    /**
    @dev Minting function common to all paths, enforces max supply.
     */
    function mint(address to, uint256 n) internal {
        n = Math.min(n, MAX_TOKENS - totalSupply());
        require(n > 0, "gmoney: no more mints");

        _safeMint(to, n);
    }

    /**
    @notice Mints an arbitrary number of tokens to an arbitrary address, only as
    the contract owner. Used to mint initial treasury and final unclaimed
    tokens.
     */
    function ownerMint(address to, uint256 n) external onlyOwner {
        mint(to, n);
    }

    /**
    @notice Maximum number of additional tokens that can be minted by those on
    the unreserved allowlist.
    @dev The number of reserved-list signatures + the number of owner mints +
    the number from this pool must never exceed MAX_TOKENS; if it does then the
    reserved pool will no longer be reserved.
     */
    int256 public unreservedRemaining = 698;

    /**
    @notice Adjusts the size of the unreserved allowlist pool.
     */
    function adjustUnreservedPool(int256 delta) external onlyOwner {
        int256 remain = unreservedRemaining + delta;
        require(remain > 0, "gmoney: negative remain");
        require(
            uint256(remain) + totalSupply() <= MAX_TOKENS,
            "gmoney: exceeds max"
        );

        unreservedRemaining = remain;
    }

    /**
    @notice Flag to indicated whether the unreserved list can mint.
     */
    bool public unreservedMintingOpen = false;

    /**
    @notice Set the unreservedMintingOpen flag.
     */
    function openUnreservedMinting(bool open) external onlyOwner {
        unreservedMintingOpen = open;
    }

    /**
    @dev Stores signed messages already used, limiting those on the allowlist to
    a single mint each.
     */
    mapping(bytes32 => bool) usedMessages;

    /**
    @notice Mint a single token as an address on one of the allowlists. Only the
    reserved pool is guaranteed to receive a mint.
     */
    function signedMint(bool reserved, bytes calldata signature) external {
        SignerManager.signers.requireValidSignature(
            signedPayload(msg.sender, reserved),
            signature,
            usedMessages
        );

        if (!reserved) {
            require(unreservedMintingOpen, "gmoney: unreserved minting closed");
            require(unreservedRemaining > 0, "gmoney: no more unreserved");
            --unreservedRemaining;
        }

        mint(msg.sender, 1);
    }

    /**
    @notice Returns whether the minter has used their signature on the
    (un)reserved list.
    @dev This function is ignorant to whether a signature actually exists for
    this address/list pair, only whether the contract has noted it as used.
     */
    function signatureUsed(address minter, bool reserved)
        external
        view
        returns (bool)
    {
        return
            usedMessages[
                SignatureChecker.generateMessage(
                    signedPayload(minter, reserved)
                )
            ];
    }

    /**
    @dev Returns the buffer that was hashed for minting signatures.
     */
    function signedPayload(address minter, bool reserved)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(minter, reserved);
    }

    /**
    @dev Required override to select the correct baseTokenURI.
     */
    function _baseURI()
        internal
        view
        override(BaseTokenURI, ERC721A)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    /**
    @notice If set, contract to which tokenURI() calls are proxied.
     */
    ITokenURIGenerator public renderingContract;

    /**
    @notice Sets the optional tokenURI override contract.
     */
    function setRenderingContract(ITokenURIGenerator _contract)
        external
        onlyOwner
    {
        renderingContract = _contract;
    }

    /**
    @notice If renderingContract is set then returns its tokenURI(tokenId)
    return value, otherwise returns the standard baseTokenURI + tokenId.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (address(renderingContract) != address(0)) {
            return renderingContract.tokenURI(tokenId);
        }
        return super.tokenURI(tokenId);
    }

    /**
    @notice Sets the default ERC2981 royalty values.
     */
    function setDefaultRoyalty(address receiver, uint96 numerator)
        external
        onlyOwner
    {
        ERC2981._setDefaultRoyalty(receiver, numerator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721ACommon, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}