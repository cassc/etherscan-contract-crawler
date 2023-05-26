// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

import "./interfaces/IScales.sol";
import "./interfaces/IScientists.sol";
import "./interfaces/ISpendable.sol";
import "./interfaces/IRWaste.sol";

error Scientists_AddressAlreadyMinted();
error Scientists_ClaimNotEnabled();
error Scientists_FunctionLocked();
error Scientists_InsufficientValue();
error Scientists_InvalidScientistData();
error Scientists_InvalidScientistId();
error Scientists_InvalidSignature();
error Scientists_ScientistAlreadyMinted();
error Scientists_SenderNotTokenOwner();

/**                                     ..',,;;;;:::;;;,,'..
                                 .';:ccccc:::;;,,,,,;;;:::ccccc:;'.
                            .,:ccc:;'..                      ..';:ccc:,.
                        .':cc:,.                                    .,ccc:'.
                     .,clc,.                                            .,clc,.
                   'clc'                                                    'clc'
                .;ll,.                                                        .;ll;.
              .:ol.                                                              'co:.
             ;oc.                                                                  .co;
           'oo'                                                                      'lo'
         .cd;                                                                          ;dc.
        .ol.                                                                 .,.        .lo.
       ,dc.                                                               'cxKWK;         cd,
      ;d;                                                             .;oONWMMMMXc         ;d;
     ;d;                                                           'cxKWMMMMMMMMMXl.        ;x;
    ,x:            ;dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx0NMMMMMMMMMMMMMMNd.        :x,
   .dc           .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.        cd.
   ld.          .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl'         .dl
  ,x;          .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0d:.             ;x,
  oo.         .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc'.                .oo
 'x:          .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;.                     :x'
 :x.           .xWMMMMMMMMMMM0occcccccccccccccccccccccccccccccccccccc:'                         .x:
 lo.            .oNMMMMMMMMMX;                                                                  .ol
.ol              .lXMMMMMMMWd.  ,dddddddddddddddo;.   .:dddddddddddddo,                          lo.
.dl                cXMMMMMM0,  'OMMMMMMMMMMMMMMNd.   .xWMMMMMMMMMMMMXo.                          ld.
.dl                 ;KMMMMNl   oWMMMMMMMMMMMMMXc.   ,OWMMMMMMMMMMMMK:                            ld.
 oo                  ,OWMMO.  ,KMMMMMMMMMMMMW0;   .cKMMMMMMMMMMMMWO,                             oo
 cd.                  'kWX:  .xWMMMMMMMMMMMWx.  .dKNMMMMMMMMMMMMNd.                             .dc
 ,x,                   .dd.  ;KMMMMMMMMMMMXo.  'kWMMMMMMMMMMMMMXl.                              ,x;
 .dc                     .   .,:loxOKNWMMK:   ;0WMMMMMMMMMMMMW0;                                cd.
  :d.                      ...      ..,:c'  .lXMMMMMMMMMMMMMWk'                                .d:
  .dl                      :OKOxoc:,..     .xNMMMMMMMMMMMMMNo.                                 cd.
   ;x,                      ;0MMMMWWXKOxoclOWMMMMMMMMMMMMMKc                                  ,x;
    cd.                      ,OWMMMMMMMMMMMMMMMMMMMMMMMMWO,                                  .dc
    .oo.                      .kWMMMMMMMMMMMMMMMMMMMMMMNx.                                  .oo.
     .oo.                      .xWMMMMMMMMMMMMMMMMMMMMXl.                                  .oo.
      .lo.                      .oNMMMMMMMMMMMMMMMMMW0;                                   .ol.
       .cd,                      .lXMMMMMMMMMMMMMMMWk'                                   ,dc.
         ;dc.                      :KMMMMMMMMMMMMNKo.                                  .cd;
          .lo,                      ;0WWWWWWWWWWKc.                                   'ol.
            ,ol.                     .,,,,,,,,,,.                                   .lo,
             .;oc.                                                                .co:.
               .;ol'                                                            'lo;.
                  ,ll:.                                                      .:ll,
                    .:ll;.                                                .;ll:.
                       .:ll:,.                                        .,:ll:.
                          .,:ccc;'.                              .';ccc:,.
                              .';cccc::;'...            ...';:ccccc;'.
                                    .',;::cc::cc::::::::::::;,..
                                              ........
 * @title Scientists
 * @author Augminted Labs, LLC
 * @notice Scientists passively earn $SCALES, DNA, and KAIJU
 * @notice For more details see: https://medium.com/@AugmintedLabs/kaijukingz-p2e-ecosystem-dc9577ff8773
 */
contract Scientists is IScientists, ERC721AQueryable, Ownable, AccessControl, ReentrancyGuard {
    using ECDSA for bytes32;

    struct ScientistInfo {
        bytes32 data;
        uint256 claimed;
        uint256 stake;
    }

    struct MintConfig {
        uint256 minimumUtilityPayment;
        uint256 minimumFxPayment;
        address signer;
    }

    event EmploymentContractSigned(
        address indexed account,
        uint256 indexed tokenId,
        bytes32 indexed scientistData
    );

    event IncreaseStake(
        uint256 indexed tokenId,
        uint256 stake
    );

    bytes32 public constant POOL_CONTROLLER_ROLE = keccak256("POOL_CONTROLLER_ROLE");
    bytes32 public constant FX_MASK = 0x0000000000000000000000000000ffffff000000000000000000000000000000;

    IScales public Scales;
    MintConfig public mintConfig;
    uint256 public totalStake;
    uint256 public scalesPool;
    uint256 public paidScientistSupply;
    mapping(uint256 => uint256) public paidScientists;
    mapping(uint256 => ScientistInfo) public scientistInfo;
    mapping(bytes32 => bool) public scientistMinted;
    mapping(address => bool) public addressMinted;
    mapping(bytes4 => bool) public functionLocked;
    string internal baseTokenURI;

    constructor(address scales)
        ERC721A("Scientists", "SCIENTIST")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        Scales = IScales(scales);

        mintConfig = MintConfig({
            minimumUtilityPayment: 0.2 ether,
            minimumFxPayment: 0.4 ether,
            signer: address(0)
        });
    }

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
        if (functionLocked[msg.sig]) revert Scientists_FunctionLocked();
        _;
    }

    /**
     * @notice Get random owner of a paid SCIENTIST
     * @return address Random paid SCIENTIST owner
     */
    function getRandomPaidScientistOwner(uint256 randomness) public view override returns (address) {
        return paidScientistSupply == 0
            ? 0x000000000000000000000000000000000000dEaD
            : ownerOf(paidScientists[randomness % paidScientistSupply]);
    }

    /**
     * @notice Get claimable $SCALES for a SCIENTIST
     * @param tokenId SCIENTIST to get the claimable $SCALES from
     * @return uint256 Amount of $SCALES claimable for a specified SCIENTIST
     */
    function getClaimable(uint256 tokenId) public view returns (uint256) {
        ScientistInfo memory _scientistInfo = scientistInfo[tokenId];

        return _scientistInfo.stake < mintConfig.minimumUtilityPayment
            ? 0
            : ((_scientistInfo.stake * scalesPool) / totalStake) - _scientistInfo.claimed;
    }

    /**
     * @notice Get the stake of a specified SCIENTIST
     * @param tokenId Valid SCIENTIST
     */
    function stake(uint256 tokenId) public view returns (uint256) {
        if (tokenId >= _totalMinted()) revert Scientists_InvalidScientistId();

        return scientistInfo[tokenId].stake;
    }

    /**
     * @inheritdoc ERC721A
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @notice Set base token URI
     * @param URI Base metadata URI to be prepended to token ID
     */
    function setBaseTokenURI(string memory URI) external lockable onlyRole(DEFAULT_ADMIN_ROLE) {
        baseTokenURI = URI;
    }

    /**
     * @notice Set $SCALES token address
     * @param scales Address of $SCALES token contract
     */
    function setScales(address scales) external lockable onlyRole(DEFAULT_ADMIN_ROLE) {
        Scales = IScales(scales);
    }

    /**
     * @notice Set configuration for mint
     * @param _mintConfig Struct with updated configuration values
     */
    function setMintConfig(MintConfig calldata _mintConfig) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintConfig = _mintConfig;
    }

    /**
     * @notice Mint a SCIENTIST
     * @dev Scientist data is validated off-chain to reduce transaction cost
     * @param scientistData Byte string representing SCIENTIST traits
     * @param signature Signature created by mintConfig.signer using validated SCIENTIST data as input
     */
    function mint(bytes32 scientistData, bytes memory signature)
        public
        payable
        lockable
        nonReentrant
    {
        if (addressMinted[_msgSender()]) revert Scientists_AddressAlreadyMinted();
        if (scientistMinted[scientistData]) revert Scientists_ScientistAlreadyMinted();

        if (scientistData & FX_MASK > 0 && msg.value < mintConfig.minimumFxPayment)
            revert Scientists_InsufficientValue();

        if (mintConfig.signer != ECDSA.recover(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_msgSender(), scientistData))),
            signature
        )) revert Scientists_InvalidSignature();

        uint256 tokenId = _totalMinted();
        scientistInfo[tokenId].data = scientistData;
        scientistMinted[scientistData] = true;
        addressMinted[_msgSender()] = true;

        _mint(_msgSender(), 1);

        if (msg.value > 0) _increaseStake(tokenId);

        emit EmploymentContractSigned(_msgSender(), tokenId, scientistData);
    }

    /**
     * @notice Increase the stake for an already minted SCIENTIST
     * @param tokenId SCIENTIST to increase stake for
     */
    function increaseStake(uint256 tokenId)
        public
        payable
        lockable
        nonReentrant
    {
        if (_msgSender() != ownerOf(tokenId)) revert Scientists_SenderNotTokenOwner();

        _increaseStake(tokenId);
    }

    /**
     * @notice Increase the stake for an already minted SCIENTIST
     * @param tokenId SCIENTIST to increase stake for
     */
    function _increaseStake(uint256 tokenId) internal {
        if (scientistInfo[tokenId].stake == 0) {
            if (msg.value < mintConfig.minimumUtilityPayment) revert Scientists_InsufficientValue();

            paidScientists[paidScientistSupply] = tokenId;
            ++paidScientistSupply;
        }

        scientistInfo[tokenId].stake += msg.value;
        totalStake += msg.value;

        emit IncreaseStake(tokenId, scientistInfo[tokenId].stake);
    }

    /**
     * @notice Increase the amount of $SCALES in the pool
     * @param amount $SCALES to add to the pool
     */
    function increasePool(uint256 amount) public override onlyRole(POOL_CONTROLLER_ROLE) {
        scalesPool += amount;
    }

    /**
     * @notice Claim $SCALES earned by a SCIENTIST
     * @dev $SCALES are credited to the sender's account, not actually minted
     * @param tokenId SCIENTIST to claim the $SCALES from
     */
    function claimScales(uint256 tokenId) public {
        if (_msgSender() != ownerOf(tokenId)) revert Scientists_SenderNotTokenOwner();
        if (!functionLocked[this.increaseStake.selector]) revert Scientists_ClaimNotEnabled();

        _claimScales(tokenId);
    }

    /**
     * @notice Claim $SCALES earned by a SCIENTIST
     * @dev $SCALES are credited to the sender's account, not actually minted
     * @param tokenId SCIENTIST to claim the $SCALES from
     */
    function _claimScales(uint256 tokenId) internal {
        uint256 claimable = getClaimable(tokenId);

        scientistInfo[tokenId].claimed += claimable;

        Scales.credit(ownerOf(tokenId), claimable);
    }

    /**
     * @inheritdoc ERC721A
     * @dev Claims earned $SCALES when a token is transferred
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721A, IERC721)
    {
        if (functionLocked[this.increaseStake.selector]) _claimScales(tokenId);

        ERC721A.transferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc ERC721A
     * @dev Claims earned $SCALES when a token is transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721A, IERC721)
    {
        if (functionLocked[this.increaseStake.selector]) _claimScales(tokenId);

        ERC721A.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @inheritdoc ERC721A
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Withdraw all ETH transferred to the contract
     */
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        Address.sendValue(payable(_msgSender()), address(this).balance);
    }

    /**
     * @notice Lock mint and increase stake functions
     * @dev WARNING: This cannot be undone
     */
    function lockMint() external onlyRole(DEFAULT_ADMIN_ROLE) {
        lockFunction(this.mint.selector);
        lockFunction(this.increaseStake.selector);
    }

    /**
     * @notice Lock individual functions that are no longer needed
     * @dev Only affects functions with the lockable modifier
     * @param id First 4 bytes of the calldata (i.e. function identifier)
     */
    function lockFunction(bytes4 id) public onlyRole(DEFAULT_ADMIN_ROLE) {
        functionLocked[id] = true;
    }
}