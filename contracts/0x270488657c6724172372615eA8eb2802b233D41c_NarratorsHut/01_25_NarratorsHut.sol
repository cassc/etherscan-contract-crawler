//SPDX-License-Identifier: MIT
//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)

pragma solidity ^0.8.17;

/*
.・。.・゜✭・.・✫・゜・。..・。.・゜✭・.・✫・゜・。.✭・.・✫・゜・。..・✫・゜・。.・。.・゜✭・.・✫・゜・。..・。.・゜✭・.・✫・゜・。.✭・.・✫・゜・。..・✫・゜・。

                                                 ▄┐
                                   ▓▌        ▓▓╓██▌
                                   ████▓██████████`
                                  ▄████████████████µ
                                ▄█████████████╬█████▄Γ
                             ╓▓█████████████▓╬╬██████▓▄
                          ,▄████████████▓▓▓▒╬╠╬████████▓,.......
                      ,▄▄██████████████▓▓█▒╬▒╠╣╬▓▓╬╠▓▓▓██▓▄░░░░░.┌
                   ..'╙╙│▀▀██████▓████████▓▓▓▓▓▓▓▓▓╣▓▓▓█▀╙╙▀░░░░░│.
                  .¡░░░░╬╣▒███╬▓╫▓╫▓╫████▓██▓▓▓▓████████▒ε░░╓▓▓▓▓▀⌐
                 ┌.¡░░░░╟╫╣██████████████▓██████▓▓▓▓▓█████████▓████▌─
                '.│░░░Q▄▓█████████████████████▓▓█▓▓██████████▓▓████▓▄▄
                 ,▄▓▓████████████████████▓█▓█▓▓▓▓█▓▒╚╚█▓▓██▓▓▓▓██████▓▓═
               "╠╠▀████████████████████▓▓█▓█▓▓▓█▓▓▓░░▒╣╬▓╣██▓▓▓█████▌   φε
                └╠░████╣██╬██▓█████████▓▓▓▓▓▓███▓▓▓╬╬╬╣▓▓╣█▓████████▓████▒
              ▐▌╓╠▄╣████████▓▓██████████████████▓▓▓╬▓▓▓╬▓╣▓██████▓██▓▀▀▀▀░╛
              ║█████████████████████████████████▓▓╣██▓█╣▓╣▓▓▓╣╬╣╬╬╬╬▒╠│░'"
              ╚████████████████████████████████▓▓╣╬▓▀▓█▓▓╣▓▓▓▓▓▓▓▓╬╬╠▒░.
            ,Q ╓▄░░╬╚███████████████████████████▓╫▓▓▓███▓▓╬▓█▓▓╬▓▓╬╬▒░░
           ]██▌ └ⁿ"░╚╚░╚╚▀▀▀██▀█████████████████▓▓▓█▓█▓▓███▓▓▓▓╬╣▓╬╬▀Γ=
             ¬       '''"░""Γ"░Γ░░Γ╙╙▀▀▀▀█████████████╬███▓╬▓▓██╬╬▓░░░'
                                     ' `"""""░╚╙╟╚╚╚╠╣╬╬╬╬╬▓▓▀╬╩▒▓▓▓∩'
                                                    ` "└└╙"╙╙Γ""`

                                                       s                                            _                                 
                         ..                           :8                                           u                                  
             .u    .    @L           .d``            .88           u.                       u.    88Nu.   u.                u.    u.  
      .    .d88B :@8c  9888i   .dL   @8Ne.   .u     :888ooo  ...ue888b           .    ...ue888b  '88888.o888c      .u     [email protected] [email protected]
 .udR88N  ="8888f8888r `Y888k:*888.  %8888:[email protected]  -*8888888  888R Y888r     .udR88N   888R Y888r  ^8888  8888   ud8888.  ^"8888""8888"
<888'888k   4888>'88"    888E  888I   `888I  888.   8888     888R I888>    <888'888k  888R I888>   8888  8888 :888'8888.   8888  888R 
9888 'Y"    4888> '      888E  888I    888I  888I   8888     888R I888>    9888 'Y"   888R I888>   8888  8888 d888 '88%"   8888  888R 
9888        4888>        888E  888I    888I  888I   8888     888R I888>    9888       888R I888>   8888  8888 8888.+"      8888  888R 
9888       .d888L .+     888E  888I  uW888L  888'  .8888Lu= u8888cJ888     9888      u8888cJ888   .8888b.888P 8888L        8888  888R 
?8888u../  ^"8888*"     x888N><888' '*88888Nu88P   ^%888*    "*888*P"      ?8888u../  "*888*P"     ^Y8888*""  '8888c. .+  "*88*" 8888"
 "8888P'      "Y"        "88"  888  ~ '88888F`       'Y"       'Y"          "8888P'     'Y"          `Y"       "88888%      ""   'Y"  
   "P'                         88F     888 ^                                  "P'                                "YP'                 
                              98"      *8E                                                                                            
                            ./"        '8>                                                                                            
                           ~`           "                                                                                             

.・。.・゜✭・.・✫・゜・。..・。.・゜✭・.・✫・゜・。.✭・.・✫・゜・。..・✫・゜・。.・。.・゜✭・.・✫・゜・。..・。.・゜✭・.・✫・゜・。.✭・.・✫・゜・。..・✫・゜・。
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./utils/Signatures.sol";

import "./ERC721Hut.sol";
import "./interfaces/INarratorsHut.sol";

contract NarratorsHut is INarratorsHut, ERC721Hut, IERC2981, Ownable {
    uint256 private tokenCounter;
    string private baseURI;

    bool public isSaleActive = false;

    // Mapping to keep track of whether a combination of
    // address, artifactId, and witchId have minted an artifact.
    mapping(bytes32 => uint256) private _tokenIdsByMintKey;

    address public metadataContractAddress;
    address public narratorAddress;

    bool private isOpenSeaConduitActive = true;

    // Domain Separator is the EIP-712 defined structure that defines what contract
    // and chain these signatures can be used for. This ensures people can't take
    // a signature used to mint on one contract and use it for another, or a signature
    // from testnet to replay on mainnet.
    // It has to be created in the constructor so we can dynamically grab the chainId.
    bytes32 private immutable domainSeparator;

    constructor(
        address _metadataContractAddress,
        address _narratorAddress,
        string memory _baseURI
    ) ERC721Hut("The Narrator's Hut", "HUT") {
        // This should match what's in the client side signing code
        domainSeparator = keccak256(
            abi.encode(
                Signatures.DOMAIN_TYPEHASH,
                keccak256(bytes("MintToken")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        metadataContractAddress = _metadataContractAddress;
        narratorAddress = _narratorAddress;
        baseURI = _baseURI;
    }

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier saleIsActive() {
        if (!isSaleActive) revert SaleIsNotActive();
        _;
    }

    modifier isCorrectPayment(uint256 totalCost) {
        if (totalCost != msg.value) revert IncorrectPaymentReceived();
        _;
    }

    modifier isValidMintSignature(
        bytes calldata mintSignature,
        uint256 totalCost,
        uint256 expiresAt,
        TokenData[] calldata tokenDataArray
    ) {
        if (narratorAddress == address(0)) {
            revert InvalidNarratorAddress();
        }
        if (block.timestamp >= expiresAt) {
            revert MintSignatureHasExpired();
        }
        // NOTE: we don't use an explicit nonce for the signature
        // since we are enforcing on-chain that a combination of
        // address, witchId, and artifactId can only ever mint once.
        // This implicitly doubles as our nonce for the signature,
        // since it also ensures a signature can only be used once
        // and prevents any replay attacks.
        bytes32 recreatedHash = Signatures.recreateMintHash(
            domainSeparator,
            msg.sender,
            totalCost,
            expiresAt,
            tokenDataArray
        );

        if (
            !SignatureChecker.isValidSignatureNow(
                narratorAddress,
                recreatedHash,
                mintSignature
            )
        ) {
            revert InvalidMintSignature();
        }
        _;
    }

    modifier canMintArtifact(TokenData calldata tokenData) {
        if (
            getTokenIdForArtifact(
                msg.sender,
                tokenData.artifactId,
                tokenData.witchId
            ) > 0
        ) {
            revert ArtifactCapReached();
        }

        INarratorsHutMetadata metadataContract = INarratorsHutMetadata(
            metadataContractAddress
        );
        if (!metadataContract.canMintArtifact(tokenData.artifactId)) {
            revert ArtifactIsNotMintable();
        }
        _;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    function mint(MintInput calldata mintInput)
        external
        payable
        saleIsActive
        isValidMintSignature(
            mintInput.mintSignature,
            mintInput.totalCost,
            mintInput.expiresAt,
            mintInput.tokenDataArray
        )
        isCorrectPayment(mintInput.totalCost)
    {
        for (uint256 i; i < mintInput.tokenDataArray.length; ) {
            mintArtifact(mintInput.tokenDataArray[i]);
            unchecked {
                ++i;
            }
        }
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function getArtifactForToken(uint256 tokenId)
        external
        view
        returns (ArtifactManifestation memory)
    {
        (uint256 artifactId, uint256 witchId) = _getDataForToken(tokenId);
        return
            INarratorsHutMetadata(metadataContractAddress).getArtifactForToken(
                artifactId,
                tokenId,
                witchId
            );
    }

    function getTokenIdForArtifact(
        address addr,
        uint48 artifactId,
        uint48 witchId
    ) public view returns (uint256) {
        bytes32 mintKey = getMintKey(addr, artifactId, witchId);
        return _tokenIdsByMintKey[mintKey];
    }

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function totalSupply() external view returns (uint256) {
        return tokenCounter;
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function setIsSaleActive(bool _status) external onlyOwner {
        isSaleActive = _status;
    }

    // enables us to disable gasless listings for security in case
    // opensea ever shuts down or is compromised
    function setIsOpenSeaConduitActive(bool _isOpenSeaConduitActive)
        external
        onlyOwner
    {
        isOpenSeaConduitActive = _isOpenSeaConduitActive;
    }

    function setMetadataContractAddress(address _metadataContractAddress)
        external
        onlyOwner
    {
        metadataContractAddress = _metadataContractAddress;
    }

    function setNarratorAddress(address _narratorAddress) external onlyOwner {
        narratorAddress = _narratorAddress;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert PaymentBalanceZero();
        }

        (bool success, bytes memory result) = owner().call{value: balance}("");
        if (!success) {
            revert PaymentUnsuccessful(result);
        }
    }

    function withdrawToken(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) {
            revert PaymentBalanceZero();
        }
        token.transfer(msg.sender, balance);
    }

    // ============ SUPPORTING FUNCTIONS ============

    function nextTokenId() private returns (uint256) {
        unchecked {
            ++tokenCounter;
        }
        return tokenCounter;
    }

    function getMintKey(
        address addr,
        uint48 artifactId,
        uint48 witchId
    ) private pure returns (bytes32) {
        // We keep track of whether a witch or an address have minted
        // artifacts of a specific type in order to enforce a mint
        // cap of one artifact type per witch, or per address if
        // not a witch owner.
        if (witchId != 0) {
            // If minting with a witch, record that the witch has
            // minted the specified artifact type
            return bytes32(abi.encodePacked(witchId, artifactId));
        } else {
            // If minting without a witch, record that the address has
            // minted the specified artifact type
            return bytes32(abi.encodePacked(addr, artifactId));
        }
    }

    function mintArtifact(TokenData calldata tokenData)
        private
        canMintArtifact(tokenData)
    {
        uint256 tokenId = nextTokenId();

        // Record that the witch, or address, has minted the
        // given artifact type
        bytes32 mintKey = getMintKey(
            msg.sender,
            tokenData.artifactId,
            tokenData.witchId
        );
        _tokenIdsByMintKey[mintKey] = tokenId;

        _mint(msg.sender, tokenId, tokenData.artifactId, tokenData.witchId);
    }

    // ============ FUNCTION OVERRIDES ============

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Hut, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (
            isOpenSeaConduitActive &&
            // NOTE: Now that OpenSea has migrated to Seaport, we can check if
            // the operator is OpenSea's conduit.
            // The address is the same across all networks thanks to CREATE2.
            operator == 0x1E0049783F008A0085193E00003D00cd54003c71
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert TokenURIQueryForNonexistentToken();

        string memory url = string.concat(
            baseURI,
            "/",
            Strings.toString(tokenId)
        );
        return url;
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (!_exists(tokenId)) revert RoyaltiesQueryForNonexistentToken();

        return (owner(), (salePrice * 5) / 100);
    }

    // ============ ERRORS ============

    error SaleIsNotActive();
    error IncorrectPaymentReceived();
    error ArtifactCapReached();
    error ArtifactIsNotMintable();
    error RoyaltiesQueryForNonexistentToken();
    error TokenURIQueryForNonexistentToken();
    error MintSignatureHasExpired();
    error InvalidNarratorAddress();
    error InvalidMintSignature();
    error PaymentBalanceZero();
    error PaymentUnsuccessful(bytes result);
}