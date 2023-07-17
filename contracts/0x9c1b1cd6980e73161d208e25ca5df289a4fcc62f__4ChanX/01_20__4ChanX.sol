// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/RevokableOperatorFilterer.sol";

/**
 * @author Created with HeyMint Launchpad https://launchpad.heymint.xyz
 * @notice This contract handles minting $4Chan X tokens.
 */
contract _4ChanX is
    ERC1155Supply,
    Ownable,
    Pausable,
    ReentrancyGuard,
    ERC2981,
    RevokableOperatorFilterer
{
    using ECDSA for bytes32;

    // Default address to subscribe to for determining blocklisted exchanges
    address constant DEFAULT_SUBSCRIPTION =
        address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
    // Used to validate authorized presale mint addresses
    address private presaleSignerAddress =
        0x110EA37D6BF74063708022c7562549C1a9314522;
    // Address where HeyMint fees are sent
    address public heymintPayoutAddress =
        0xE1FaC470dE8dE91c66778eaa155C64c7ceEFc851;
    address public royaltyAddress = 0xFA1030B5625623352E2c07F7A0B1bb601fca6344;
    address[] public paperAddresses = [
        0xf3DB642663231887E2Ff3501da6E3247D8634A6D,
        0x5e01a33C75931aD0A91A12Ee016Be8D61b24ADEB,
        0x9E733848061e4966c4a920d5b99a123459670aEe,
        0x7754B94345BCE520f8dd4F6a5642567603e90E10
    ];
    address[] public payoutAddresses = [
        0xFA1030B5625623352E2c07F7A0B1bb601fca6344
    ];
    // Permanently freezes metadata for all tokens so they can never be changed
    bool public allMetadataFrozen = false;
    // If true, payout addresses and basis points are permanently frozen and can never be updated
    bool public payoutAddressesFrozen;
    // The amount of tokens minted by a given address for a given token id
    mapping(address => mapping(uint256 => uint256))
        public tokensMintedByAddress;
    // Permanently freezes metadata for a specific token id so it can never be changed
    mapping(uint256 => bool) public tokenMetadataFrozen;
    // If true, the given token id can never be minted again
    mapping(uint256 => bool) public tokenMintingPermanentlyDisabled;
    mapping(uint256 => bool) public tokenPresaleSaleActive;
    mapping(uint256 => bool) public tokenPublicSaleActive;
    // If true, sale start and end times for the presale will be enforced, else ignored
    mapping(uint256 => bool) public tokenUsePresaleTimes;
    // If true, sale start and end times for the public sale will be enforced, else ignored
    mapping(uint256 => bool) public tokenUsePublicSaleTimes;
    mapping(uint256 => string) public tokenURI;
    // Maximum supply of tokens that can be minted for each token id. If zero, this token is open edition and has no mint limit
    mapping(uint256 => uint256) public tokenMaxSupply;
    // If zero, this token is open edition and has no mint limit
    mapping(uint256 => uint256) public tokenPresaleMaxSupply;
    mapping(uint256 => uint256) public tokenPresaleMintsPerAddress;
    mapping(uint256 => uint256) public tokenPresalePrice;
    mapping(uint256 => uint256) public tokenPresaleSaleEndTime;
    mapping(uint256 => uint256) public tokenPresaleSaleStartTime;
    mapping(uint256 => uint256) public tokenPublicMintsPerAddress;
    mapping(uint256 => uint256) public tokenPublicPrice;
    mapping(uint256 => uint256) public tokenPublicSaleEndTime;
    mapping(uint256 => uint256) public tokenPublicSaleStartTime;
    string public name = "$4Chan X";
    string public symbol = "4CX";
    // Fee paid to HeyMint per NFT minted
    uint256 public heymintFeePerToken;
    // The respective share of funds to be sent to each address in payoutAddresses in basis points
    uint256[] public payoutBasisPoints = [10000];
    uint96 public royaltyFee = 1000;

    constructor(
        uint256 _heymintFeePerToken
    )
        ERC1155(
            "ipfs://bafybeif2da74gdkn25bzmslnhkdthymhgjlvivhdvqnqa3nu57fwydwx4u/{id}"
        )
        RevokableOperatorFilterer(
            0x000000000000AAeB6D7670E522A718067333cd4E,
            DEFAULT_SUBSCRIPTION,
            true
        )
    {
        heymintFeePerToken = _heymintFeePerToken;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
        tokenMaxSupply[1] = 1;
        tokenPublicPrice[1] = 0.03 ether;
        tokenPublicMintsPerAddress[1] = 1;
        tokenMaxSupply[2] = 1;
        tokenPublicPrice[2] = 0.03 ether;
        tokenPublicMintsPerAddress[2] = 1;
        tokenMaxSupply[3] = 1;
        tokenPublicPrice[3] = 0.03 ether;
        tokenPublicMintsPerAddress[3] = 1;
        tokenMaxSupply[5] = 1;
        tokenPublicPrice[5] = 0.03 ether;
        tokenPublicMintsPerAddress[5] = 1;
        tokenMaxSupply[6] = 1;
        tokenPublicPrice[6] = 0.03 ether;
        tokenPublicMintsPerAddress[6] = 1;
        tokenMaxSupply[7] = 1;
        tokenPublicPrice[7] = 0.03 ether;
        tokenPublicMintsPerAddress[7] = 1;
        tokenMaxSupply[8] = 1;
        tokenPublicPrice[8] = 0.03 ether;
        tokenPublicMintsPerAddress[8] = 1;
        tokenMaxSupply[9] = 1;
        tokenPublicPrice[9] = 0.03 ether;
        tokenPublicMintsPerAddress[9] = 1;
        tokenMaxSupply[10] = 1;
        tokenPublicPrice[10] = 0.03 ether;
        tokenPublicMintsPerAddress[10] = 1;
        tokenMaxSupply[11] = 1;
        tokenPublicPrice[11] = 0.03 ether;
        tokenPublicMintsPerAddress[11] = 1;
        tokenMaxSupply[12] = 1;
        tokenPublicPrice[12] = 0.03 ether;
        tokenPublicMintsPerAddress[12] = 1;
        tokenMaxSupply[13] = 1;
        tokenPublicPrice[13] = 0.03 ether;
        tokenPublicMintsPerAddress[13] = 1;
        tokenMaxSupply[14] = 1;
        tokenPublicPrice[14] = 0.03 ether;
        tokenPublicMintsPerAddress[14] = 1;
        tokenMaxSupply[16] = 1;
        tokenPublicPrice[16] = 0.03 ether;
        tokenPublicMintsPerAddress[16] = 1;
        tokenMaxSupply[17] = 1;
        tokenPublicPrice[17] = 0.03 ether;
        tokenPublicMintsPerAddress[17] = 1;
        tokenMaxSupply[18] = 1;
        tokenPublicPrice[18] = 0.03 ether;
        tokenPublicMintsPerAddress[18] = 1;
        tokenMaxSupply[19] = 1;
        tokenPublicPrice[19] = 0.03 ether;
        tokenPublicMintsPerAddress[19] = 1;
        tokenMaxSupply[20] = 1;
        tokenPublicPrice[20] = 0.03 ether;
        tokenPublicMintsPerAddress[20] = 1;
        tokenMaxSupply[21] = 1;
        tokenPublicPrice[21] = 0.03 ether;
        tokenPublicMintsPerAddress[21] = 1;
        tokenMaxSupply[22] = 1;
        tokenPublicPrice[22] = 0.03 ether;
        tokenPublicMintsPerAddress[22] = 1;
        tokenMaxSupply[23] = 1;
        tokenPublicPrice[23] = 0.03 ether;
        tokenPublicMintsPerAddress[23] = 1;
        tokenMaxSupply[24] = 1;
        tokenPublicPrice[24] = 0.03 ether;
        tokenPublicMintsPerAddress[24] = 1;
        tokenMaxSupply[25] = 1;
        tokenPublicPrice[25] = 0.03 ether;
        tokenPublicMintsPerAddress[25] = 1;
        tokenMaxSupply[26] = 1;
        tokenPublicPrice[26] = 0.03 ether;
        tokenPublicMintsPerAddress[26] = 1;
        tokenMaxSupply[27] = 1;
        tokenPublicPrice[27] = 0.03 ether;
        tokenPublicMintsPerAddress[27] = 1;
        tokenMaxSupply[28] = 1;
        tokenPublicPrice[28] = 0.03 ether;
        tokenPublicMintsPerAddress[28] = 1;
        tokenMaxSupply[29] = 1;
        tokenPublicPrice[29] = 0.03 ether;
        tokenPublicMintsPerAddress[29] = 1;
        tokenMaxSupply[30] = 1;
        tokenPublicPrice[30] = 0.03 ether;
        tokenPublicMintsPerAddress[30] = 1;
        tokenMaxSupply[31] = 1;
        tokenPublicPrice[31] = 0.03 ether;
        tokenPublicMintsPerAddress[31] = 1;
        tokenMaxSupply[32] = 1;
        tokenPublicPrice[32] = 0.03 ether;
        tokenPublicMintsPerAddress[32] = 1;
        tokenMaxSupply[33] = 1;
        tokenPublicPrice[33] = 0.03 ether;
        tokenPublicMintsPerAddress[33] = 1;
        tokenMaxSupply[34] = 1;
        tokenPublicPrice[34] = 0.03 ether;
        tokenPublicMintsPerAddress[34] = 1;
        tokenMaxSupply[35] = 1;
        tokenPublicPrice[35] = 0.03 ether;
        tokenPublicMintsPerAddress[35] = 1;
        tokenMaxSupply[36] = 1;
        tokenPublicPrice[36] = 0.03 ether;
        tokenPublicMintsPerAddress[36] = 1;
        tokenMaxSupply[37] = 1;
        tokenPublicPrice[37] = 0.03 ether;
        tokenPublicMintsPerAddress[37] = 1;
        tokenMaxSupply[38] = 1;
        tokenPublicPrice[38] = 0.03 ether;
        tokenPublicMintsPerAddress[38] = 1;
        tokenMaxSupply[39] = 1;
        tokenPublicPrice[39] = 0.03 ether;
        tokenPublicMintsPerAddress[39] = 1;
        tokenMaxSupply[40] = 1;
        tokenPublicPrice[40] = 0.03 ether;
        tokenPublicMintsPerAddress[40] = 1;
        tokenMaxSupply[41] = 1;
        tokenPublicPrice[41] = 0.03 ether;
        tokenPublicMintsPerAddress[41] = 1;
        tokenMaxSupply[42] = 1;
        tokenPublicPrice[42] = 0.03 ether;
        tokenPublicMintsPerAddress[42] = 1;
        tokenMaxSupply[44] = 1;
        tokenPublicPrice[44] = 0.03 ether;
        tokenPublicMintsPerAddress[44] = 1;
        tokenMaxSupply[45] = 1;
        tokenPublicPrice[45] = 0.03 ether;
        tokenPublicMintsPerAddress[45] = 1;
        tokenMaxSupply[46] = 1;
        tokenPublicPrice[46] = 0.03 ether;
        tokenPublicMintsPerAddress[46] = 1;
        tokenMaxSupply[49] = 1;
        tokenPublicPrice[49] = 0.03 ether;
        tokenPublicMintsPerAddress[49] = 1;
        tokenMaxSupply[50] = 1;
        tokenPublicPrice[50] = 0.03 ether;
        tokenPublicMintsPerAddress[50] = 1;
        tokenMaxSupply[51] = 1;
        tokenPublicPrice[51] = 0.03 ether;
        tokenPublicMintsPerAddress[51] = 1;
        tokenMaxSupply[52] = 1;
        tokenPublicPrice[52] = 0.03 ether;
        tokenPublicMintsPerAddress[52] = 1;
        tokenMaxSupply[53] = 1;
        tokenPublicPrice[53] = 0.03 ether;
        tokenPublicMintsPerAddress[53] = 1;
        tokenMaxSupply[54] = 1;
        tokenPublicPrice[54] = 0.03 ether;
        tokenPublicMintsPerAddress[54] = 1;
        tokenMaxSupply[56] = 1;
        tokenPublicPrice[56] = 0.03 ether;
        tokenPublicMintsPerAddress[56] = 1;
        tokenMaxSupply[57] = 1;
        tokenPublicPrice[57] = 0.03 ether;
        tokenPublicMintsPerAddress[57] = 1;
        tokenMaxSupply[59] = 1;
        tokenPublicPrice[59] = 0.03 ether;
        tokenPublicMintsPerAddress[59] = 1;
        tokenMaxSupply[60] = 1;
        tokenPublicPrice[60] = 0.03 ether;
        tokenPublicMintsPerAddress[60] = 1;
        tokenMaxSupply[61] = 1;
        tokenPublicPrice[61] = 0.03 ether;
        tokenPublicMintsPerAddress[61] = 1;
        tokenMaxSupply[62] = 1;
        tokenPublicPrice[62] = 0.03 ether;
        tokenPublicMintsPerAddress[62] = 1;
        tokenMaxSupply[65] = 1;
        tokenPublicPrice[65] = 0.03 ether;
        tokenPublicMintsPerAddress[65] = 1;
        tokenMaxSupply[66] = 1;
        tokenPublicPrice[66] = 0.03 ether;
        tokenPublicMintsPerAddress[66] = 1;
        tokenMaxSupply[69] = 1;
        tokenPublicPrice[69] = 0.03 ether;
        tokenPublicMintsPerAddress[69] = 1;
        tokenMaxSupply[70] = 1;
        tokenPublicPrice[70] = 0.03 ether;
        tokenPublicMintsPerAddress[70] = 1;
        tokenMaxSupply[72] = 1;
        tokenPublicPrice[72] = 0.03 ether;
        tokenPublicMintsPerAddress[72] = 1;
        tokenMaxSupply[73] = 1;
        tokenPublicPrice[73] = 0.03 ether;
        tokenPublicMintsPerAddress[73] = 1;
        tokenMaxSupply[74] = 1;
        tokenPublicPrice[74] = 0.03 ether;
        tokenPublicMintsPerAddress[74] = 1;
        tokenMaxSupply[76] = 1;
        tokenPublicPrice[76] = 0.03 ether;
        tokenPublicMintsPerAddress[76] = 1;
        tokenMaxSupply[77] = 1;
        tokenPublicPrice[77] = 0.03 ether;
        tokenPublicMintsPerAddress[77] = 1;
        tokenMaxSupply[78] = 1;
        tokenPublicPrice[78] = 0.03 ether;
        tokenPublicMintsPerAddress[78] = 1;
        tokenMaxSupply[79] = 1;
        tokenPublicPrice[79] = 0.03 ether;
        tokenPublicMintsPerAddress[79] = 1;
        tokenMaxSupply[80] = 1;
        tokenPublicPrice[80] = 0.03 ether;
        tokenPublicMintsPerAddress[80] = 1;
        tokenMaxSupply[81] = 1;
        tokenPublicPrice[81] = 0.03 ether;
        tokenPublicMintsPerAddress[81] = 1;
        tokenMaxSupply[82] = 1;
        tokenPublicPrice[82] = 0.03 ether;
        tokenPublicMintsPerAddress[82] = 1;
        tokenMaxSupply[83] = 1;
        tokenPublicPrice[83] = 0.03 ether;
        tokenPublicMintsPerAddress[83] = 1;
        tokenMaxSupply[84] = 1;
        tokenPublicPrice[84] = 0.03 ether;
        tokenPublicMintsPerAddress[84] = 1;
        tokenMaxSupply[85] = 1;
        tokenPublicPrice[85] = 0.03 ether;
        tokenPublicMintsPerAddress[85] = 1;
        tokenMaxSupply[86] = 1;
        tokenPublicPrice[86] = 0.03 ether;
        tokenPublicMintsPerAddress[86] = 1;
        tokenMaxSupply[88] = 1;
        tokenPublicPrice[88] = 0.03 ether;
        tokenPublicMintsPerAddress[88] = 1;
        tokenMaxSupply[89] = 1;
        tokenPublicPrice[89] = 0.03 ether;
        tokenPublicMintsPerAddress[89] = 1;
        tokenMaxSupply[90] = 1;
        tokenPublicPrice[90] = 0.03 ether;
        tokenPublicMintsPerAddress[90] = 1;
        tokenMaxSupply[91] = 1;
        tokenPublicPrice[91] = 0.03 ether;
        tokenPublicMintsPerAddress[91] = 1;
        tokenMaxSupply[92] = 1;
        tokenPublicPrice[92] = 0.03 ether;
        tokenPublicMintsPerAddress[92] = 1;
        tokenMaxSupply[93] = 1;
        tokenPublicPrice[93] = 0.03 ether;
        tokenPublicMintsPerAddress[93] = 1;
        tokenMaxSupply[94] = 1;
        tokenPublicPrice[94] = 0.03 ether;
        tokenPublicMintsPerAddress[94] = 1;
        tokenMaxSupply[95] = 1;
        tokenPublicPrice[95] = 0.03 ether;
        tokenPublicMintsPerAddress[95] = 1;
        tokenMaxSupply[96] = 1;
        tokenPublicPrice[96] = 0.03 ether;
        tokenPublicMintsPerAddress[96] = 1;
        tokenMaxSupply[97] = 1;
        tokenPublicPrice[97] = 0.03 ether;
        tokenPublicMintsPerAddress[97] = 1;
        tokenMaxSupply[98] = 1;
        tokenPublicPrice[98] = 0.03 ether;
        tokenPublicMintsPerAddress[98] = 1;
        tokenMaxSupply[100] = 1;
        tokenPublicPrice[100] = 0.03 ether;
        tokenPublicMintsPerAddress[100] = 1;
        tokenMaxSupply[101] = 1;
        tokenPublicPrice[101] = 0.03 ether;
        tokenPublicMintsPerAddress[101] = 1;
        tokenMaxSupply[102] = 1;
        tokenPublicPrice[102] = 0.03 ether;
        tokenPublicMintsPerAddress[102] = 1;
        tokenMaxSupply[103] = 1;
        tokenPublicPrice[103] = 0.03 ether;
        tokenPublicMintsPerAddress[103] = 1;
        tokenMaxSupply[104] = 1;
        tokenPublicPrice[104] = 0.03 ether;
        tokenPublicMintsPerAddress[104] = 1;
        tokenMaxSupply[105] = 1;
        tokenPublicPrice[105] = 0.03 ether;
        tokenPublicMintsPerAddress[105] = 1;
        tokenMaxSupply[106] = 1;
        tokenPublicPrice[106] = 0.03 ether;
        tokenPublicMintsPerAddress[106] = 1;
        tokenMaxSupply[108] = 1;
        tokenPublicPrice[108] = 0.03 ether;
        tokenPublicMintsPerAddress[108] = 1;
        tokenMaxSupply[109] = 1;
        tokenPublicPrice[109] = 0.03 ether;
        tokenPublicMintsPerAddress[109] = 1;
        tokenMaxSupply[110] = 1;
        tokenPublicPrice[110] = 0.03 ether;
        tokenPublicMintsPerAddress[110] = 1;
        tokenMaxSupply[111] = 1;
        tokenPublicPrice[111] = 0.03 ether;
        tokenPublicMintsPerAddress[111] = 1;
        tokenMaxSupply[112] = 1;
        tokenPublicPrice[112] = 0.03 ether;
        tokenPublicMintsPerAddress[112] = 1;
        tokenMaxSupply[113] = 1;
        tokenPublicPrice[113] = 0.03 ether;
        tokenPublicMintsPerAddress[113] = 1;
        tokenMaxSupply[114] = 1;
        tokenPublicPrice[114] = 0.03 ether;
        tokenPublicMintsPerAddress[114] = 1;
        tokenMaxSupply[115] = 1;
        tokenPublicPrice[115] = 0.03 ether;
        tokenPublicMintsPerAddress[115] = 1;
        tokenMaxSupply[116] = 1;
        tokenPublicPrice[116] = 0.03 ether;
        tokenPublicMintsPerAddress[116] = 1;
        tokenMaxSupply[117] = 1;
        tokenPublicPrice[117] = 0.03 ether;
        tokenPublicMintsPerAddress[117] = 1;
        tokenMaxSupply[118] = 1;
        tokenPublicPrice[118] = 0.03 ether;
        tokenPublicMintsPerAddress[118] = 1;
        tokenMaxSupply[120] = 1;
        tokenPublicPrice[120] = 0.03 ether;
        tokenPublicMintsPerAddress[120] = 1;
        tokenMaxSupply[121] = 1;
        tokenPublicPrice[121] = 0.03 ether;
        tokenPublicMintsPerAddress[121] = 1;
        tokenMaxSupply[122] = 1;
        tokenPublicPrice[122] = 0.03 ether;
        tokenPublicMintsPerAddress[122] = 1;
        tokenMaxSupply[123] = 1;
        tokenPublicPrice[123] = 0.03 ether;
        tokenPublicMintsPerAddress[123] = 1;
        tokenMaxSupply[124] = 1;
        tokenPublicPrice[124] = 0.03 ether;
        tokenPublicMintsPerAddress[124] = 1;
        tokenMaxSupply[125] = 1;
        tokenPublicPrice[125] = 0.03 ether;
        tokenPublicMintsPerAddress[125] = 1;
        tokenMaxSupply[126] = 1;
        tokenPublicPrice[126] = 0.03 ether;
        tokenPublicMintsPerAddress[126] = 1;
        tokenMaxSupply[127] = 1;
        tokenPublicPrice[127] = 0.03 ether;
        tokenPublicMintsPerAddress[127] = 1;
        tokenMaxSupply[129] = 1;
        tokenPublicPrice[129] = 0.03 ether;
        tokenPublicMintsPerAddress[129] = 1;
        tokenMaxSupply[130] = 1;
        tokenPublicPrice[130] = 0.03 ether;
        tokenPublicMintsPerAddress[130] = 1;
        tokenMaxSupply[131] = 1;
        tokenPublicPrice[131] = 0.03 ether;
        tokenPublicMintsPerAddress[131] = 1;
        tokenMaxSupply[132] = 1;
        tokenPublicPrice[132] = 0.03 ether;
        tokenPublicMintsPerAddress[132] = 1;
        tokenMaxSupply[134] = 1;
        tokenPublicPrice[134] = 0.03 ether;
        tokenPublicMintsPerAddress[134] = 1;
        tokenMaxSupply[135] = 1;
        tokenPublicPrice[135] = 0.03 ether;
        tokenPublicMintsPerAddress[135] = 1;
        tokenMaxSupply[136] = 1;
        tokenPublicPrice[136] = 0.03 ether;
        tokenPublicMintsPerAddress[136] = 1;
        tokenMaxSupply[137] = 1;
        tokenPublicPrice[137] = 0.03 ether;
        tokenPublicMintsPerAddress[137] = 1;
        tokenMaxSupply[138] = 1;
        tokenPublicPrice[138] = 0.03 ether;
        tokenPublicMintsPerAddress[138] = 1;
        tokenMaxSupply[139] = 1;
        tokenPublicPrice[139] = 0.03 ether;
        tokenPublicMintsPerAddress[139] = 1;
        tokenMaxSupply[140] = 1;
        tokenPublicPrice[140] = 0.03 ether;
        tokenPublicMintsPerAddress[140] = 1;
        tokenMaxSupply[141] = 1;
        tokenPublicPrice[141] = 0.03 ether;
        tokenPublicMintsPerAddress[141] = 1;
        tokenMaxSupply[142] = 1;
        tokenPublicPrice[142] = 0.03 ether;
        tokenPublicMintsPerAddress[142] = 1;
        tokenMaxSupply[144] = 1;
        tokenPublicPrice[144] = 0.03 ether;
        tokenPublicMintsPerAddress[144] = 1;
        tokenMaxSupply[145] = 1;
        tokenPublicPrice[145] = 0.03 ether;
        tokenPublicMintsPerAddress[145] = 1;
        tokenMaxSupply[146] = 1;
        tokenPublicPrice[146] = 0.03 ether;
        tokenPublicMintsPerAddress[146] = 1;
        tokenMaxSupply[147] = 1;
        tokenPublicPrice[147] = 0.03 ether;
        tokenPublicMintsPerAddress[147] = 1;
        tokenMaxSupply[148] = 1;
        tokenPublicPrice[148] = 0.03 ether;
        tokenPublicMintsPerAddress[148] = 1;
        tokenMaxSupply[149] = 1;
        tokenPublicPrice[149] = 0.03 ether;
        tokenPublicMintsPerAddress[149] = 1;
        tokenMaxSupply[151] = 1;
        tokenPublicPrice[151] = 0.03 ether;
        tokenPublicMintsPerAddress[151] = 1;
        tokenMaxSupply[152] = 1;
        tokenPublicPrice[152] = 0.03 ether;
        tokenPublicMintsPerAddress[152] = 1;
        tokenMaxSupply[153] = 1;
        tokenPublicPrice[153] = 0.03 ether;
        tokenPublicMintsPerAddress[153] = 1;
        tokenMaxSupply[154] = 1;
        tokenPublicPrice[154] = 0.03 ether;
        tokenPublicMintsPerAddress[154] = 1;
        tokenMaxSupply[155] = 1;
        tokenPublicPrice[155] = 0.03 ether;
        tokenPublicMintsPerAddress[155] = 1;
        tokenMaxSupply[157] = 1;
        tokenPublicPrice[157] = 0.03 ether;
        tokenPublicMintsPerAddress[157] = 1;
        tokenMaxSupply[158] = 1;
        tokenPublicPrice[158] = 0.03 ether;
        tokenPublicMintsPerAddress[158] = 1;
        tokenMaxSupply[159] = 1;
        tokenPublicPrice[159] = 0.03 ether;
        tokenPublicMintsPerAddress[159] = 1;
        tokenMaxSupply[160] = 1;
        tokenPublicPrice[160] = 0.03 ether;
        tokenPublicMintsPerAddress[160] = 1;
        tokenMaxSupply[162] = 1;
        tokenPublicPrice[162] = 0.03 ether;
        tokenPublicMintsPerAddress[162] = 1;
        tokenMaxSupply[164] = 1;
        tokenPublicPrice[164] = 0.03 ether;
        tokenPublicMintsPerAddress[164] = 1;
        tokenMaxSupply[166] = 1;
        tokenPublicPrice[166] = 0.03 ether;
        tokenPublicMintsPerAddress[166] = 1;
        tokenMaxSupply[167] = 1;
        tokenPublicPrice[167] = 0.03 ether;
        tokenPublicMintsPerAddress[167] = 1;
        tokenMaxSupply[170] = 1;
        tokenPublicPrice[170] = 0.03 ether;
        tokenPublicMintsPerAddress[170] = 1;
        tokenMaxSupply[171] = 1;
        tokenPublicPrice[171] = 0.03 ether;
        tokenPublicMintsPerAddress[171] = 1;
        tokenMaxSupply[172] = 1;
        tokenPublicPrice[172] = 0.03 ether;
        tokenPublicMintsPerAddress[172] = 1;
        tokenMaxSupply[173] = 1;
        tokenPublicPrice[173] = 0.03 ether;
        tokenPublicMintsPerAddress[173] = 1;
        tokenMaxSupply[175] = 1;
        tokenPublicPrice[175] = 0.03 ether;
        tokenPublicMintsPerAddress[175] = 1;
        tokenMaxSupply[176] = 1;
        tokenPublicPrice[176] = 0.03 ether;
        tokenPublicMintsPerAddress[176] = 1;
        tokenMaxSupply[177] = 1;
        tokenPublicPrice[177] = 0.03 ether;
        tokenPublicMintsPerAddress[177] = 1;
        tokenMaxSupply[178] = 1;
        tokenPublicPrice[178] = 0.03 ether;
        tokenPublicMintsPerAddress[178] = 1;
        tokenMaxSupply[179] = 1;
        tokenPublicPrice[179] = 0.03 ether;
        tokenPublicMintsPerAddress[179] = 1;
        tokenMaxSupply[181] = 1;
        tokenPublicPrice[181] = 0.03 ether;
        tokenPublicMintsPerAddress[181] = 1;
        tokenMaxSupply[182] = 1;
        tokenPublicPrice[182] = 0.03 ether;
        tokenPublicMintsPerAddress[182] = 1;
        tokenMaxSupply[184] = 1;
        tokenPublicPrice[184] = 0.03 ether;
        tokenPublicMintsPerAddress[184] = 1;
        tokenMaxSupply[185] = 1;
        tokenPublicPrice[185] = 0.03 ether;
        tokenPublicMintsPerAddress[185] = 1;
        tokenMaxSupply[186] = 1;
        tokenPublicPrice[186] = 0.03 ether;
        tokenPublicMintsPerAddress[186] = 1;
        tokenMaxSupply[189] = 1;
        tokenPublicPrice[189] = 0.03 ether;
        tokenPublicMintsPerAddress[189] = 1;
        tokenMaxSupply[190] = 1;
        tokenPublicPrice[190] = 0.03 ether;
        tokenPublicMintsPerAddress[190] = 1;
        tokenMaxSupply[192] = 1;
        tokenPublicPrice[192] = 0.03 ether;
        tokenPublicMintsPerAddress[192] = 1;
        tokenMaxSupply[193] = 1;
        tokenPublicPrice[193] = 0.03 ether;
        tokenPublicMintsPerAddress[193] = 1;
        tokenMaxSupply[194] = 1;
        tokenPublicPrice[194] = 0.03 ether;
        tokenPublicMintsPerAddress[194] = 1;
        tokenMaxSupply[196] = 1;
        tokenPublicPrice[196] = 0.03 ether;
        tokenPublicMintsPerAddress[196] = 1;
        tokenMaxSupply[197] = 1;
        tokenPublicPrice[197] = 0.03 ether;
        tokenPublicMintsPerAddress[197] = 1;
        tokenMaxSupply[198] = 1;
        tokenPublicPrice[198] = 0.03 ether;
        tokenPublicMintsPerAddress[198] = 1;
        tokenMaxSupply[200] = 1;
        tokenPublicPrice[200] = 0.03 ether;
        tokenPublicMintsPerAddress[200] = 1;
        tokenMaxSupply[201] = 1;
        tokenPublicPrice[201] = 0.03 ether;
        tokenPublicMintsPerAddress[201] = 1;
        tokenMaxSupply[202] = 1;
        tokenPublicPrice[202] = 0.03 ether;
        tokenPublicMintsPerAddress[202] = 1;
        tokenMaxSupply[203] = 1;
        tokenPublicPrice[203] = 0.03 ether;
        tokenPublicMintsPerAddress[203] = 1;
        tokenMaxSupply[204] = 1;
        tokenPublicPrice[204] = 0.03 ether;
        tokenPublicMintsPerAddress[204] = 1;
        tokenMaxSupply[205] = 1;
        tokenPublicPrice[205] = 0.03 ether;
        tokenPublicMintsPerAddress[205] = 1;
        tokenMaxSupply[208] = 1;
        tokenPublicPrice[208] = 0.03 ether;
        tokenPublicMintsPerAddress[208] = 1;
        tokenMaxSupply[209] = 1;
        tokenPublicPrice[209] = 0.03 ether;
        tokenPublicMintsPerAddress[209] = 1;
        tokenMaxSupply[210] = 1;
        tokenPublicPrice[210] = 0.03 ether;
        tokenPublicMintsPerAddress[210] = 1;
        tokenMaxSupply[212] = 1;
        tokenPublicPrice[212] = 0.03 ether;
        tokenPublicMintsPerAddress[212] = 1;
        tokenMaxSupply[215] = 1;
        tokenPublicPrice[215] = 0.03 ether;
        tokenPublicMintsPerAddress[215] = 1;
        tokenMaxSupply[217] = 1;
        tokenPublicPrice[217] = 0.03 ether;
        tokenPublicMintsPerAddress[217] = 1;
        tokenMaxSupply[218] = 1;
        tokenPublicPrice[218] = 0.03 ether;
        tokenPublicMintsPerAddress[218] = 1;
        tokenMaxSupply[219] = 1;
        tokenPublicPrice[219] = 0.03 ether;
        tokenPublicMintsPerAddress[219] = 1;
        tokenMaxSupply[220] = 1;
        tokenPublicPrice[220] = 0.03 ether;
        tokenPublicMintsPerAddress[220] = 1;
        tokenMaxSupply[221] = 1;
        tokenPublicPrice[221] = 0.03 ether;
        tokenPublicMintsPerAddress[221] = 1;
        tokenMaxSupply[222] = 1;
        tokenPublicPrice[222] = 0.03 ether;
        tokenPublicMintsPerAddress[222] = 1;
        tokenMaxSupply[223] = 1;
        tokenPublicPrice[223] = 0.03 ether;
        tokenPublicMintsPerAddress[223] = 1;
        tokenMaxSupply[224] = 1;
        tokenPublicPrice[224] = 0.03 ether;
        tokenPublicMintsPerAddress[224] = 1;
        tokenMaxSupply[225] = 1;
        tokenPublicPrice[225] = 0.03 ether;
        tokenPublicMintsPerAddress[225] = 1;
        tokenMaxSupply[226] = 1;
        tokenPublicPrice[226] = 0.03 ether;
        tokenPublicMintsPerAddress[226] = 1;
        tokenMaxSupply[230] = 1;
        tokenPublicPrice[230] = 0.03 ether;
        tokenPublicMintsPerAddress[230] = 1;
        tokenMaxSupply[232] = 1;
        tokenPublicPrice[232] = 0.03 ether;
        tokenPublicMintsPerAddress[232] = 1;
        tokenMaxSupply[238] = 1;
        tokenPublicPrice[238] = 0.03 ether;
        tokenPublicMintsPerAddress[238] = 1;
        tokenMaxSupply[239] = 1;
        tokenPublicPrice[239] = 0.03 ether;
        tokenPublicMintsPerAddress[239] = 1;
        tokenMaxSupply[241] = 1;
        tokenPublicPrice[241] = 0.03 ether;
        tokenPublicMintsPerAddress[241] = 1;
        tokenMaxSupply[242] = 1;
        tokenPublicPrice[242] = 0.03 ether;
        tokenPublicMintsPerAddress[242] = 1;
        tokenMaxSupply[246] = 1;
        tokenPublicPrice[246] = 0.03 ether;
        tokenPublicMintsPerAddress[246] = 1;
        tokenMaxSupply[248] = 1;
        tokenPublicPrice[248] = 0.03 ether;
        tokenPublicMintsPerAddress[248] = 1;
        tokenMaxSupply[250] = 1;
        tokenPublicPrice[250] = 0.03 ether;
        tokenPublicMintsPerAddress[250] = 1;
        tokenMaxSupply[252] = 1;
        tokenPublicPrice[252] = 0.03 ether;
        tokenPublicMintsPerAddress[252] = 1;
        tokenMaxSupply[256] = 1;
        tokenPublicPrice[256] = 0.03 ether;
        tokenPublicMintsPerAddress[256] = 1;
        tokenMaxSupply[257] = 1;
        tokenPublicPrice[257] = 0.03 ether;
        tokenPublicMintsPerAddress[257] = 1;
        tokenMaxSupply[258] = 1;
        tokenPublicPrice[258] = 0.03 ether;
        tokenPublicMintsPerAddress[258] = 1;
        tokenMaxSupply[261] = 1;
        tokenPublicPrice[261] = 0.03 ether;
        tokenPublicMintsPerAddress[261] = 1;
        tokenMaxSupply[262] = 1;
        tokenPublicPrice[262] = 0.03 ether;
        tokenPublicMintsPerAddress[262] = 1;
        tokenMaxSupply[263] = 1;
        tokenPublicPrice[263] = 0.03 ether;
        tokenPublicMintsPerAddress[263] = 1;
        tokenMaxSupply[264] = 1;
        tokenPublicPrice[264] = 0.03 ether;
        tokenPublicMintsPerAddress[264] = 1;
        tokenMaxSupply[266] = 1;
        tokenPublicPrice[266] = 0.03 ether;
        tokenPublicMintsPerAddress[266] = 1;
        tokenMaxSupply[273] = 1;
        tokenPublicPrice[273] = 0.03 ether;
        tokenPublicMintsPerAddress[273] = 1;
        tokenMaxSupply[276] = 1;
        tokenPublicPrice[276] = 0.03 ether;
        tokenPublicMintsPerAddress[276] = 1;
        tokenMaxSupply[277] = 1;
        tokenPublicPrice[277] = 0.03 ether;
        tokenPublicMintsPerAddress[277] = 1;
        tokenMaxSupply[279] = 1;
        tokenPublicPrice[279] = 0.03 ether;
        tokenPublicMintsPerAddress[279] = 1;
        tokenMaxSupply[280] = 1;
        tokenPublicPrice[280] = 0.03 ether;
        tokenPublicMintsPerAddress[280] = 1;
        tokenMaxSupply[284] = 1;
        tokenPublicPrice[284] = 0.03 ether;
        tokenPublicMintsPerAddress[284] = 1;
        tokenMaxSupply[285] = 1;
        tokenPublicPrice[285] = 0.03 ether;
        tokenPublicMintsPerAddress[285] = 1;
        tokenMaxSupply[289] = 1;
        tokenPublicPrice[289] = 0.03 ether;
        tokenPublicMintsPerAddress[289] = 1;
        tokenMaxSupply[291] = 1;
        tokenPublicPrice[291] = 0.03 ether;
        tokenPublicMintsPerAddress[291] = 1;
        tokenMaxSupply[292] = 1;
        tokenPublicPrice[292] = 0.03 ether;
        tokenPublicMintsPerAddress[292] = 1;
        tokenMaxSupply[293] = 1;
        tokenPublicPrice[293] = 0.03 ether;
        tokenPublicMintsPerAddress[293] = 1;
        tokenMaxSupply[294] = 1;
        tokenPublicPrice[294] = 0.03 ether;
        tokenPublicMintsPerAddress[294] = 1;
        tokenMaxSupply[296] = 1;
        tokenPublicPrice[296] = 0.03 ether;
        tokenPublicMintsPerAddress[296] = 1;
        tokenMaxSupply[297] = 1;
        tokenPublicPrice[297] = 0.03 ether;
        tokenPublicMintsPerAddress[297] = 1;
        tokenMaxSupply[298] = 1;
        tokenPublicPrice[298] = 0.03 ether;
        tokenPublicMintsPerAddress[298] = 1;
        tokenMaxSupply[300] = 1;
        tokenPublicPrice[300] = 0.03 ether;
        tokenPublicMintsPerAddress[300] = 1;
        tokenMaxSupply[301] = 1;
        tokenPublicPrice[301] = 0.03 ether;
        tokenPublicMintsPerAddress[301] = 1;
        tokenMaxSupply[302] = 1;
        tokenPublicPrice[302] = 0.03 ether;
        tokenPublicMintsPerAddress[302] = 1;
        tokenMaxSupply[303] = 1;
        tokenPublicPrice[303] = 0.03 ether;
        tokenPublicMintsPerAddress[303] = 1;
        tokenMaxSupply[304] = 1;
        tokenPublicPrice[304] = 0.03 ether;
        tokenPublicMintsPerAddress[304] = 1;
        tokenMaxSupply[305] = 1;
        tokenPublicPrice[305] = 0.03 ether;
        tokenPublicMintsPerAddress[305] = 1;
        tokenMaxSupply[306] = 1;
        tokenPublicPrice[306] = 0.03 ether;
        tokenPublicMintsPerAddress[306] = 1;
        tokenMaxSupply[310] = 1;
        tokenPublicPrice[310] = 0.03 ether;
        tokenPublicMintsPerAddress[310] = 1;
        tokenMaxSupply[311] = 1;
        tokenPublicPrice[311] = 0.03 ether;
        tokenPublicMintsPerAddress[311] = 1;
        tokenMaxSupply[312] = 1;
        tokenPublicPrice[312] = 0.03 ether;
        tokenPublicMintsPerAddress[312] = 1;
        tokenMaxSupply[313] = 1;
        tokenPublicPrice[313] = 0.03 ether;
        tokenPublicMintsPerAddress[313] = 1;
        tokenMaxSupply[315] = 1;
        tokenPublicPrice[315] = 0.03 ether;
        tokenPublicMintsPerAddress[315] = 1;
        tokenMaxSupply[316] = 1;
        tokenPublicPrice[316] = 0.03 ether;
        tokenPublicMintsPerAddress[316] = 1;
        tokenMaxSupply[317] = 1;
        tokenPublicPrice[317] = 0.03 ether;
        tokenPublicMintsPerAddress[317] = 1;
        tokenMaxSupply[318] = 1;
        tokenPublicPrice[318] = 0.03 ether;
        tokenPublicMintsPerAddress[318] = 1;
        tokenMaxSupply[319] = 1;
        tokenPublicPrice[319] = 0.03 ether;
        tokenPublicMintsPerAddress[319] = 1;
        tokenMaxSupply[320] = 1;
        tokenPublicPrice[320] = 0.03 ether;
        tokenPublicMintsPerAddress[320] = 1;
        tokenMaxSupply[321] = 1;
        tokenPublicPrice[321] = 0.03 ether;
        tokenPublicMintsPerAddress[321] = 1;
        tokenMaxSupply[325] = 1;
        tokenPublicPrice[325] = 0.03 ether;
        tokenPublicMintsPerAddress[325] = 1;
        tokenMaxSupply[326] = 1;
        tokenPublicPrice[326] = 0.03 ether;
        tokenPublicMintsPerAddress[326] = 1;
        tokenMaxSupply[327] = 1;
        tokenPublicPrice[327] = 0.03 ether;
        tokenPublicMintsPerAddress[327] = 1;
        require(
            payoutAddresses.length == payoutBasisPoints.length,
            "PAYOUT_ARRAYS_NOT_SAME_LENGTH"
        );
        uint256 totalPayoutBasisPoints = 0;
        for (uint256 i = 0; i < payoutBasisPoints.length; i++) {
            totalPayoutBasisPoints += payoutBasisPoints[i];
        }
        require(
            totalPayoutBasisPoints == 10000,
            "TOTAL_BASIS_POINTS_MUST_BE_10000"
        );
    }

    modifier originalUser() {
        require(tx.origin == msg.sender, "CANNOT_CALL_FROM_CONTRACT");
        _;
    }

    /**
     * @notice Returns a custom URI for each token id if set
     */
    function uri(
        uint256 _tokenId
    ) public view override returns (string memory) {
        // If no URI exists for the specific id requested, fallback to the default ERC-1155 URI.
        if (bytes(tokenURI[_tokenId]).length == 0) {
            return super.uri(_tokenId);
        }
        return tokenURI[_tokenId];
    }

    /**
     * @notice Sets a URI for a specific token id.
     */
    function setURI(
        uint256 _tokenId,
        string calldata _newTokenURI
    ) external onlyOwner {
        require(
            !allMetadataFrozen && !tokenMetadataFrozen[_tokenId],
            "METADATA_HAS_BEEN_FROZEN"
        );
        tokenURI[_tokenId] = _newTokenURI;
    }

    /**
     * @notice Update the global default ERC-1155 base URI
     */
    function setGlobalURI(string calldata _newTokenURI) external onlyOwner {
        require(!allMetadataFrozen, "METADATA_HAS_BEEN_FROZEN");
        _setURI(_newTokenURI);
    }

    /**
     * @notice Freeze metadata for a specific token id so it can never be changed again
     */
    function freezeTokenMetadata(uint256 _tokenId) external onlyOwner {
        require(
            !tokenMetadataFrozen[_tokenId],
            "METADATA_HAS_ALREADY_BEEN_FROZEN"
        );
        tokenMetadataFrozen[_tokenId] = true;
    }

    /**
     * @notice Freeze all metadata so it can never be changed again
     */
    function freezeAllMetadata() external onlyOwner {
        require(!allMetadataFrozen, "METADATA_HAS_ALREADY_BEEN_FROZEN");
        allMetadataFrozen = true;
    }

    /**
     * @notice Reduce the max supply of tokens for a given token id
     * @param _newMaxSupply The new maximum supply of tokens available to mint
     * @param _tokenId The token id to reduce the max supply for
     */
    function reduceMaxSupply(
        uint256 _tokenId,
        uint256 _newMaxSupply
    ) external onlyOwner {
        require(
            tokenMaxSupply[_tokenId] == 0 ||
                _newMaxSupply < tokenMaxSupply[_tokenId],
            "NEW_MAX_SUPPLY_TOO_HIGH"
        );
        require(
            _newMaxSupply >= totalSupply(_tokenId),
            "SUPPLY_LOWER_THAN_MINTED_TOKENS"
        );
        tokenMaxSupply[_tokenId] = _newMaxSupply;
    }

    /**
     * @notice Lock a token id so that it can never be minted again
     */
    function permanentlyDisableTokenMinting(
        uint256 _tokenId
    ) external onlyOwner {
        tokenMintingPermanentlyDisabled[_tokenId] = true;
    }

    /**
     * @notice Change the royalty fee for the collection
     */
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Change the royalty address where royalty payouts are sent
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    /**
     * @notice Allow owner to send tokens without cost to multiple addresses
     */
    function giftTokens(
        uint256 _tokenId,
        address[] calldata _receivers,
        uint256[] calldata _mintNumber
    ) external onlyOwner {
        require(
            !tokenMintingPermanentlyDisabled[_tokenId],
            "MINTING_PERMANENTLY_DISABLED"
        );
        uint256 totalMint = 0;
        for (uint256 i = 0; i < _mintNumber.length; i++) {
            totalMint += _mintNumber[i];
        }
        // require either no tokenMaxSupply set or tokenMaxSupply not maxed out
        require(
            tokenMaxSupply[_tokenId] == 0 ||
                totalSupply(_tokenId) + totalMint <= tokenMaxSupply[_tokenId],
            "MINT_TOO_LARGE"
        );
        for (uint256 i = 0; i < _receivers.length; i++) {
            _mint(_receivers[i], _tokenId, _mintNumber[i], "");
        }
    }

    /**
     * @notice To be updated by contract owner to allow public sale minting for a given token
     */
    function setTokenPublicSaleState(
        uint256 _tokenId,
        bool _saleActiveState
    ) external onlyOwner {
        require(
            tokenPublicSaleActive[_tokenId] != _saleActiveState,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        tokenPublicSaleActive[_tokenId] = _saleActiveState;
    }

    /**
     * @notice Update the public mint price for a given token
     */
    function setTokenPublicPrice(
        uint256 _tokenId,
        uint256 _publicPrice
    ) external onlyOwner {
        tokenPublicPrice[_tokenId] = _publicPrice;
    }

    /**
     * @notice Set the maximum public mints allowed per a given address for a given token
     */
    function setTokenPublicMintsAllowedPerAddress(
        uint256 _tokenId,
        uint256 _mintsAllowed
    ) external onlyOwner {
        tokenPublicMintsPerAddress[_tokenId] = _mintsAllowed;
    }

    /**
     * @notice Update the start time for public mint for a given token
     */
    function setTokenPublicSaleStartTime(
        uint256 _tokenId,
        uint256 _publicSaleStartTime
    ) external onlyOwner {
        require(_publicSaleStartTime > block.timestamp, "TIME_IN_PAST");
        tokenPublicSaleStartTime[_tokenId] = _publicSaleStartTime;
    }

    /**
     * @notice Update the end time for public mint for a given token
     */
    function setTokenPublicSaleEndTime(
        uint256 _tokenId,
        uint256 _publicSaleEndTime
    ) external onlyOwner {
        require(_publicSaleEndTime > block.timestamp, "TIME_IN_PAST");
        tokenPublicSaleEndTime[_tokenId] = _publicSaleEndTime;
    }

    /**
     * @notice Update whether or not to use the automatic public sale times for a given token
     */
    function setTokenUsePublicSaleTimes(
        uint256 _tokenId,
        bool _usePublicSaleTimes
    ) external onlyOwner {
        require(
            tokenUsePublicSaleTimes[_tokenId] != _usePublicSaleTimes,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        tokenUsePublicSaleTimes[_tokenId] = _usePublicSaleTimes;
    }

    /**
     * @notice Returns if public sale times are active for a given token
     */
    function tokenPublicSaleTimeIsActive(
        uint256 _tokenId
    ) public view returns (bool) {
        if (tokenUsePublicSaleTimes[_tokenId] == false) {
            return true;
        }
        return
            block.timestamp >= tokenPublicSaleStartTime[_tokenId] &&
            block.timestamp <= tokenPublicSaleEndTime[_tokenId];
    }

    /**
     * @notice Allow for public minting of tokens for a given token
     */
    function mintToken(
        uint256 _tokenId,
        uint256 _numTokens
    ) external payable originalUser nonReentrant {
        require(tokenPublicSaleActive[_tokenId], "PUBLIC_SALE_IS_NOT_ACTIVE");
        require(
            tokenPublicSaleTimeIsActive(_tokenId),
            "PUBLIC_SALE_TIME_IS_NOT_ACTIVE"
        );
        require(
            tokenPublicMintsPerAddress[_tokenId] == 0 ||
                tokensMintedByAddress[msg.sender][_tokenId] + _numTokens <=
                tokenPublicMintsPerAddress[_tokenId],
            "MAX_MINTS_FOR_ADDRESS_EXCEEDED"
        );
        require(
            tokenMaxSupply[_tokenId] == 0 ||
                totalSupply(_tokenId) + _numTokens <= tokenMaxSupply[_tokenId],
            "MAX_SUPPLY_EXCEEDED"
        );
        uint256 heymintFee = _numTokens * heymintFeePerToken;
        require(
            msg.value == tokenPublicPrice[_tokenId] * _numTokens + heymintFee,
            "PAYMENT_INCORRECT"
        );
        require(
            !tokenMintingPermanentlyDisabled[_tokenId],
            "MINTING_PERMANENTLY_DISABLED"
        );

        (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
        require(success, "Transfer failed.");
        tokensMintedByAddress[msg.sender][_tokenId] += _numTokens;
        _mint(msg.sender, _tokenId, _numTokens, "");

        if (
            tokenMaxSupply[_tokenId] != 0 &&
            totalSupply(_tokenId) >= tokenMaxSupply[_tokenId]
        ) {
            tokenPublicSaleActive[_tokenId] = false;
        }
    }

    /**
     * @notice Mint using a credit card
     */
    function creditCardMint(
        uint256 _tokenId,
        uint256 _numTokens,
        address _to
    ) external payable originalUser nonReentrant {
        bool authorized = false;
        for (uint256 i = 0; i < paperAddresses.length; i++) {
            if (msg.sender == paperAddresses[i]) {
                authorized = true;
                break;
            }
        }
        require(authorized, "NOT_AUTHORIZED_ADDRESS");

        require(tokenPublicSaleActive[_tokenId], "PUBLIC_SALE_IS_NOT_ACTIVE");
        require(
            tokenPublicSaleTimeIsActive(_tokenId),
            "PUBLIC_SALE_TIME_IS_NOT_ACTIVE"
        );
        require(
            tokenPublicMintsPerAddress[_tokenId] == 0 ||
                tokensMintedByAddress[_to][_tokenId] + _numTokens <=
                tokenPublicMintsPerAddress[_tokenId],
            "MAX_MINTS_FOR_ADDRESS_EXCEEDED"
        );
        require(
            tokenMaxSupply[_tokenId] == 0 ||
                totalSupply(_tokenId) + _numTokens <= tokenMaxSupply[_tokenId],
            "MAX_SUPPLY_EXCEEDED"
        );

        uint256 heymintFee = _numTokens * heymintFeePerToken;
        require(
            msg.value == tokenPublicPrice[_tokenId] * _numTokens + heymintFee,
            "PAYMENT_INCORRECT"
        );
        require(
            !tokenMintingPermanentlyDisabled[_tokenId],
            "MINTING_PERMANENTLY_DISABLED"
        );

        (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
        require(success, "Transfer failed.");
        tokensMintedByAddress[_to][_tokenId] += _numTokens;
        _mint(_to, _tokenId, _numTokens, "");

        if (
            tokenMaxSupply[_tokenId] != 0 &&
            totalSupply(_tokenId) >= tokenMaxSupply[_tokenId]
        ) {
            tokenPublicSaleActive[_tokenId] = false;
        }
    }

    /**
     * @notice Set the signer address used to verify presale minting
     */
    function setPresaleSignerAddress(
        address _presaleSignerAddress
    ) external onlyOwner {
        require(_presaleSignerAddress != address(0));
        presaleSignerAddress = _presaleSignerAddress;
    }

    /**
     * @notice To be updated by contract owner to allow presale minting for a given token
     */
    function setTokenPresaleState(
        uint256 _tokenId,
        bool _saleActiveState
    ) external onlyOwner {
        require(
            tokenPresaleSaleActive[_tokenId] != _saleActiveState,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        tokenPresaleSaleActive[_tokenId] = _saleActiveState;
    }

    /**
     * @notice Update the presale mint price for a given token
     */
    function setTokenPresalePrice(
        uint256 _tokenId,
        uint256 _presalePrice
    ) external onlyOwner {
        tokenPresalePrice[_tokenId] = _presalePrice;
    }

    /**
     * @notice Set the maximum presale mints allowed per a given address for a given token
     */
    function setTokenPresaleMintsAllowedPerAddress(
        uint256 _tokenId,
        uint256 _mintsAllowed
    ) external onlyOwner {
        tokenPresaleMintsPerAddress[_tokenId] = _mintsAllowed;
    }

    /**
     * @notice Reduce the presale max supply of tokens for a given token id
     * @param _newPresaleMaxSupply The new maximum supply of tokens available to mint
     * @param _tokenId The token id to reduce the max supply for
     */
    function reducePresaleMaxSupply(
        uint256 _tokenId,
        uint256 _newPresaleMaxSupply
    ) external onlyOwner {
        require(
            tokenPresaleMaxSupply[_tokenId] == 0 ||
                _newPresaleMaxSupply < tokenPresaleMaxSupply[_tokenId],
            "NEW_MAX_SUPPLY_TOO_HIGH"
        );
        tokenPresaleMaxSupply[_tokenId] = _newPresaleMaxSupply;
    }

    /**
     * @notice Update the start time for presale mint for a given token
     */
    function setTokenPresaleStartTime(
        uint256 _tokenId,
        uint256 _presaleStartTime
    ) external onlyOwner {
        require(_presaleStartTime > block.timestamp, "TIME_IN_PAST");
        tokenPresaleSaleStartTime[_tokenId] = _presaleStartTime;
    }

    /**
     * @notice Update the end time for presale mint for a given token
     */
    function setTokenPresaleEndTime(
        uint256 _tokenId,
        uint256 _presaleEndTime
    ) external onlyOwner {
        require(_presaleEndTime > block.timestamp, "TIME_IN_PAST");
        tokenPresaleSaleEndTime[_tokenId] = _presaleEndTime;
    }

    /**
     * @notice Update whether or not to use the automatic presale times for a given token
     */
    function setTokenUsePresaleTimes(
        uint256 _tokenId,
        bool _usePresaleTimes
    ) external onlyOwner {
        require(
            tokenUsePresaleTimes[_tokenId] != _usePresaleTimes,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        tokenUsePresaleTimes[_tokenId] = _usePresaleTimes;
    }

    /**
     * @notice Returns if presale times are active for a given token
     */
    function tokenPresaleTimeIsActive(
        uint256 _tokenId
    ) public view returns (bool) {
        if (tokenUsePresaleTimes[_tokenId] == false) {
            return true;
        }
        return
            block.timestamp >= tokenPresaleSaleStartTime[_tokenId] &&
            block.timestamp <= tokenPresaleSaleEndTime[_tokenId];
    }

    /**
     * @notice Verify that a signed message is validly signed by the presaleSignerAddress
     */
    function verifySignerAddress(
        bytes32 _messageHash,
        bytes calldata _signature
    ) private view returns (bool) {
        return
            presaleSignerAddress ==
            _messageHash.toEthSignedMessageHash().recover(_signature);
    }

    /**
     * @notice Allow for allowlist minting of tokens
     */
    function presaleMint(
        bytes32 _messageHash,
        bytes calldata _signature,
        uint256 _tokenId,
        uint256 _numTokens,
        uint256 _maximumAllowedMints
    ) external payable originalUser nonReentrant {
        require(tokenPresaleSaleActive[_tokenId], "PRESALE_IS_NOT_ACTIVE");
        require(
            tokenPresaleTimeIsActive(_tokenId),
            "PRESALE_TIME_IS_NOT_ACTIVE"
        );
        require(
            !tokenMintingPermanentlyDisabled[_tokenId],
            "MINTING_PERMANENTLY_DISABLED"
        );
        require(
            tokenPresaleMintsPerAddress[_tokenId] == 0 ||
                tokensMintedByAddress[msg.sender][_tokenId] + _numTokens <=
                tokenPresaleMintsPerAddress[_tokenId],
            "MAX_MINTS_PER_ADDRESS_EXCEEDED"
        );
        require(
            _maximumAllowedMints == 0 ||
                tokensMintedByAddress[msg.sender][_tokenId] + _numTokens <=
                _maximumAllowedMints,
            "MAX_MINTS_EXCEEDED"
        );
        require(
            tokenPresaleMaxSupply[_tokenId] == 0 ||
                totalSupply(_tokenId) + _numTokens <=
                tokenPresaleMaxSupply[_tokenId],
            "MAX_SUPPLY_EXCEEDED"
        );
        uint256 heymintFee = _numTokens * heymintFeePerToken;
        require(
            msg.value == tokenPresalePrice[_tokenId] * _numTokens + heymintFee,
            "PAYMENT_INCORRECT"
        );
        require(
            keccak256(abi.encode(msg.sender, _maximumAllowedMints, _tokenId)) ==
                _messageHash,
            "MESSAGE_INVALID"
        );
        require(
            verifySignerAddress(_messageHash, _signature),
            "SIGNATURE_VALIDATION_FAILED"
        );

        (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
        require(success, "Transfer failed.");
        tokensMintedByAddress[msg.sender][_tokenId] += _numTokens;
        _mint(msg.sender, _tokenId, _numTokens, "");

        if (
            tokenPresaleMaxSupply[_tokenId] != 0 &&
            totalSupply(_tokenId) >= tokenPresaleMaxSupply[_tokenId]
        ) {
            tokenPresaleSaleActive[_tokenId] = false;
        }
    }

    /**
     * @notice Freeze all payout addresses and percentages so they can never be changed again
     */
    function freezePayoutAddresses() external onlyOwner {
        require(!payoutAddressesFrozen, "PAYOUT_ADDRESSES_ALREADY_FROZEN");
        payoutAddressesFrozen = true;
    }

    /**
     * @notice Update payout addresses and basis points for each addresses' respective share of contract funds
     */
    function updatePayoutAddressesAndBasisPoints(
        address[] calldata _payoutAddresses,
        uint256[] calldata _payoutBasisPoints
    ) external onlyOwner {
        require(!payoutAddressesFrozen, "PAYOUT_ADDRESSES_FROZEN");
        require(
            _payoutAddresses.length == _payoutBasisPoints.length,
            "ARRAY_LENGTHS_MUST_MATCH"
        );
        uint256 totalBasisPoints = 0;
        for (uint i = 0; i < _payoutBasisPoints.length; i++) {
            totalBasisPoints += _payoutBasisPoints[i];
        }
        require(totalBasisPoints == 10000, "TOTAL_BASIS_POINTS_MUST_BE_10000");
        payoutAddresses = _payoutAddresses;
        payoutBasisPoints = _payoutBasisPoints;
    }

    /**
     * @notice Withdraws all funds held within contract
     */
    function withdraw() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "CONTRACT_HAS_NO_BALANCE");
        require(payoutAddresses.length > 0, "NO_PAYOUT_ADDRESSES");
        uint256 balance = address(this).balance;
        for (uint i = 0; i < payoutAddresses.length; i++) {
            uint256 amount = (balance * payoutBasisPoints[i]) / 10000;
            (bool success, ) = payoutAddresses[i].call{value: amount}("");
            require(success, "Transfer failed.");
        }
    }

    /**
     * @notice Override default ERC-1155 setApprovalForAll to require that the operator is not from a blocklisted exchange
     * @param operator Address to add to the set of authorized operators
     * @param approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @notice Override ERC1155 such that zero amount token transfers are disallowed.
     * This prevents arbitrary 'creation' of new tokens in the collection by anyone.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        require(amount > 0, "AMOUNT_CANNOT_BE_ZERO");
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }
}