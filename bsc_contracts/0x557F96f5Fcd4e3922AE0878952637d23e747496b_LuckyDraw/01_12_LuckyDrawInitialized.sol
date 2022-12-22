// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ISpaceRegistration.sol";

contract LuckyDraw is VRFConsumerBaseV2, ConfirmedOwner, ReentrancyGuard {
    using Counters for Counters.Counter;

    event CreateLottery(uint256 id);
    event Fund(uint256 indexed lotId, uint256 amount);
    event Join(uint256 indexed lotId, address indexed user, uint256 tickets);
    event Claimed(uint256 indexed lotId, address indexed user);

    /**
     * VRF events
     */
    event RequestSent(uint256 lotId);
    event RequestFulfilled(uint256 lotId, uint256[] randomWords);
    
    struct Lottery {
        uint spaceId;
        address creator;

        /**
        * For a non-tokenized random draw, tokenAddr = address(0)
        */
        address tokenAddr;
        uint256 pool;
        uint256 claimed;

        /**
        * winners & winnerRatios:
        * Winners are able to claim the indexed ratios of the pool. Other participants share the rest of the pool;
        * For a generalized giveaway, winners is set 0 and winnerRatios of length 0;
        * For a common lucky draw, sum(winnerRatios) = 100;
        */
        uint32 winners;
        uint256[] winnerRatios;

        /**
        * Users are randomly drawed as winners with the possibilities based on tickets.
        */
        uint256 maxTickets;
        uint256 ticketPrice;
        mapping(address => uint256[]) indexedTickets;
        address[] tickets;

        uint256 vrfRequestId;
        uint256 start;
        uint256 end;
        mapping(address => bool) claimedAddrs;
        Counters.Counter counter;

        /**
        * Signature to msg = abi.encodePacked(lotId, msg.sender)
        */
        bool requireSig;
    }

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
        uint256 lotId;
    }
    Lottery[] lotteries;

    // After life the creator is able to withdraw the remaining pool
    uint256 private life = 30 * 24 * 3600;

    // Signature verification contract if requireSig
    // bnb: 0x6D9e5B24F3a82a42F3698c1664004E9f1fBD9cEA
    // bnb test: 0x28F569e8E38659fbE5d84D18cDA901B157D6Dd84
    ISpaceRegistration spaceRegistration = ISpaceRegistration(0x6D9e5B24F3a82a42F3698c1664004E9f1fBD9cEA);

    /**
     * VRF settings
     */
    uint64 s_subscriptionId;
    // bnb: 0xba6e730de88d94a5510ae6613898bfb0c3de5d16e609c5b7da808747125506f7
    // bnb testnet: 0xd4bb89654db74673a187bd804519e65e3f71a52bc55f11da7601a13dcf505314
    bytes32 keyHash =
        0xba6e730de88d94a5510ae6613898bfb0c3de5d16e609c5b7da808747125506f7;
    uint32 callbackGasLimit = 1000000;
    uint16 requestConfirmations = 3;
    VRFCoordinatorV2Interface COORDINATOR;

    // bnb: 0xc587d9053cd1118f25F645F9E08BB98c9712A4EE
    // bnb testnet: 0x6A2AAd07396B36Fe02a22b33cf443582f682c82f
    address private vrfCoordinatorAddr = 0xc587d9053cd1118f25F645F9E08BB98c9712A4EE;

    mapping(uint256 => RequestStatus) private s_requests;

    constructor(uint64 subscriptionId)
        VRFConsumerBaseV2(vrfCoordinatorAddr)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinatorAddr);
        s_subscriptionId = subscriptionId;
        init();
    }

    function init() internal{
        Lottery storage lot0 = lotteries.push();
        lot0.spaceId = 0;
        lot0.creator = 0x830732Ee350fBaB3A7C322a695f47dc26778F60d;
        lot0.tokenAddr = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        lot0.pool = 1698000000000000000000;
        lot0.maxTickets = 10;
        lot0.ticketPrice = 1000000000000000000;
        lot0.winnerRatios = [50,20,10];
        lot0.winners = 3;
        lot0.start = 1670059244;
        lot0.end = 1671580800;
        lot0.requireSig = true;
        lot0.tickets = [0x830732Ee350fBaB3A7C322a695f47dc26778F60d,0xCE67B694bC268E7D9431e658A149657d46F80387,0xCE67B694bC268E7D9431e658A149657d46F80387,0xCE67B694bC268E7D9431e658A149657d46F80387,0xCE67B694bC268E7D9431e658A149657d46F80387,0xCE67B694bC268E7D9431e658A149657d46F80387,0xCE67B694bC268E7D9431e658A149657d46F80387,0xCE67B694bC268E7D9431e658A149657d46F80387,0xCE67B694bC268E7D9431e658A149657d46F80387,0xCE67B694bC268E7D9431e658A149657d46F80387,0xCE67B694bC268E7D9431e658A149657d46F80387,0x3D6db46E3A98F1D996aeAc9bbfBa570D0a60b4F7,0x3D6db46E3A98F1D996aeAc9bbfBa570D0a60b4F7,0x3D6db46E3A98F1D996aeAc9bbfBa570D0a60b4F7,0x3D6db46E3A98F1D996aeAc9bbfBa570D0a60b4F7,0x3D6db46E3A98F1D996aeAc9bbfBa570D0a60b4F7,0x3D6db46E3A98F1D996aeAc9bbfBa570D0a60b4F7,0x3D6db46E3A98F1D996aeAc9bbfBa570D0a60b4F7,0x3D6db46E3A98F1D996aeAc9bbfBa570D0a60b4F7,0x3D6db46E3A98F1D996aeAc9bbfBa570D0a60b4F7,0x3D6db46E3A98F1D996aeAc9bbfBa570D0a60b4F7,0x112D960C88de18482C5f4069c0286a5a57Bab086,0xDF55bBE2e152E55644C531eCf8697752BcCdb0C0,0xDF55bBE2e152E55644C531eCf8697752BcCdb0C0,0xDF55bBE2e152E55644C531eCf8697752BcCdb0C0,0xDF55bBE2e152E55644C531eCf8697752BcCdb0C0,0xDF55bBE2e152E55644C531eCf8697752BcCdb0C0,0xDF55bBE2e152E55644C531eCf8697752BcCdb0C0,0xDF55bBE2e152E55644C531eCf8697752BcCdb0C0,0xDF55bBE2e152E55644C531eCf8697752BcCdb0C0,0xDF55bBE2e152E55644C531eCf8697752BcCdb0C0,0xDF55bBE2e152E55644C531eCf8697752BcCdb0C0,0x72D6960AAe3C90e2de304f6fb89263a7FCca14bB,0x72D6960AAe3C90e2de304f6fb89263a7FCca14bB,0x72D6960AAe3C90e2de304f6fb89263a7FCca14bB,0x72D6960AAe3C90e2de304f6fb89263a7FCca14bB,0x72D6960AAe3C90e2de304f6fb89263a7FCca14bB,0x72D6960AAe3C90e2de304f6fb89263a7FCca14bB,0x72D6960AAe3C90e2de304f6fb89263a7FCca14bB,0x72D6960AAe3C90e2de304f6fb89263a7FCca14bB,0x72D6960AAe3C90e2de304f6fb89263a7FCca14bB,0x72D6960AAe3C90e2de304f6fb89263a7FCca14bB,0x830732Ee350fBaB3A7C322a695f47dc26778F60d,0x04a7CD054708F6D3a45994B957bE91ac9e34A687,0xd31A84c20bc430aD75E6a1903E7dDbee52211072,0xd31A84c20bc430aD75E6a1903E7dDbee52211072,0xd31A84c20bc430aD75E6a1903E7dDbee52211072,0xd31A84c20bc430aD75E6a1903E7dDbee52211072,0xd31A84c20bc430aD75E6a1903E7dDbee52211072,0xd31A84c20bc430aD75E6a1903E7dDbee52211072,0xd31A84c20bc430aD75E6a1903E7dDbee52211072,0xd31A84c20bc430aD75E6a1903E7dDbee52211072,0xd31A84c20bc430aD75E6a1903E7dDbee52211072,0xd31A84c20bc430aD75E6a1903E7dDbee52211072,0x5C36436eb678cEbBF2f77Aa52F8310141931D984,0x5C36436eb678cEbBF2f77Aa52F8310141931D984,0x5C36436eb678cEbBF2f77Aa52F8310141931D984,0x5C36436eb678cEbBF2f77Aa52F8310141931D984,0x5C36436eb678cEbBF2f77Aa52F8310141931D984,0x5C36436eb678cEbBF2f77Aa52F8310141931D984,0x5C36436eb678cEbBF2f77Aa52F8310141931D984,0x5C36436eb678cEbBF2f77Aa52F8310141931D984,0x5C36436eb678cEbBF2f77Aa52F8310141931D984,0x5C36436eb678cEbBF2f77Aa52F8310141931D984,0x83a27BE9bc9c98A6Cd504570B4fa1899ae09F95f,0x83a27BE9bc9c98A6Cd504570B4fa1899ae09F95f,0x83a27BE9bc9c98A6Cd504570B4fa1899ae09F95f,0x83a27BE9bc9c98A6Cd504570B4fa1899ae09F95f,0x83a27BE9bc9c98A6Cd504570B4fa1899ae09F95f,0x83a27BE9bc9c98A6Cd504570B4fa1899ae09F95f,0x83a27BE9bc9c98A6Cd504570B4fa1899ae09F95f,0x83a27BE9bc9c98A6Cd504570B4fa1899ae09F95f,0x83a27BE9bc9c98A6Cd504570B4fa1899ae09F95f,0x83a27BE9bc9c98A6Cd504570B4fa1899ae09F95f,0x755309E7A48B97c9a2Ba87661A75B26df8431Ec2,0x755309E7A48B97c9a2Ba87661A75B26df8431Ec2,0x755309E7A48B97c9a2Ba87661A75B26df8431Ec2,0x755309E7A48B97c9a2Ba87661A75B26df8431Ec2,0x755309E7A48B97c9a2Ba87661A75B26df8431Ec2,0xfefE83C39cEeE44F799068DCac8755D1D89358D9,0xfefE83C39cEeE44F799068DCac8755D1D89358D9,0xfefE83C39cEeE44F799068DCac8755D1D89358D9,0xfefE83C39cEeE44F799068DCac8755D1D89358D9,0xfefE83C39cEeE44F799068DCac8755D1D89358D9,0xfefE83C39cEeE44F799068DCac8755D1D89358D9,0xfefE83C39cEeE44F799068DCac8755D1D89358D9,0xfefE83C39cEeE44F799068DCac8755D1D89358D9,0xfefE83C39cEeE44F799068DCac8755D1D89358D9,0xfefE83C39cEeE44F799068DCac8755D1D89358D9,0x8202F1fF3A94e199d970919d8D71Ffb434b6F627,0x29dBC979b45B2F45B8BB41f612f80DCD8B2ef446,0xb7985A153FF4C8fc197b859F6f7979B126Aaa315,0x8202F1fF3A94e199d970919d8D71Ffb434b6F627,0x86c16F44BC75851a9E2E16e28366aDD78169fEA9,0x86c16F44BC75851a9E2E16e28366aDD78169fEA9,0x0a3C464FFD7458C5f4EB09a314A00623327957B8,0x0a3C464FFD7458C5f4EB09a314A00623327957B8,0x0a3C464FFD7458C5f4EB09a314A00623327957B8,0x37b3cE4eE95758e41B0E73EA3088eA9c3FdaCd32,0x06a559acEDE9E7872dE280E6b8545Ff5c01c62ab,0xFACb9eE3931231c4AD49787605d0d8637DC21133,0xFACb9eE3931231c4AD49787605d0d8637DC21133,0xFACb9eE3931231c4AD49787605d0d8637DC21133,0xFACb9eE3931231c4AD49787605d0d8637DC21133,0xFACb9eE3931231c4AD49787605d0d8637DC21133,0xFACb9eE3931231c4AD49787605d0d8637DC21133,0xFACb9eE3931231c4AD49787605d0d8637DC21133,0xFACb9eE3931231c4AD49787605d0d8637DC21133,0xFACb9eE3931231c4AD49787605d0d8637DC21133,0xFACb9eE3931231c4AD49787605d0d8637DC21133,0xAefCDA6b2cF4EcC7A7E07099C79a729a7c8b91f7,0xAefCDA6b2cF4EcC7A7E07099C79a729a7c8b91f7,0xAefCDA6b2cF4EcC7A7E07099C79a729a7c8b91f7,0xAefCDA6b2cF4EcC7A7E07099C79a729a7c8b91f7,0xAefCDA6b2cF4EcC7A7E07099C79a729a7c8b91f7,0xAefCDA6b2cF4EcC7A7E07099C79a729a7c8b91f7,0xAefCDA6b2cF4EcC7A7E07099C79a729a7c8b91f7,0xAefCDA6b2cF4EcC7A7E07099C79a729a7c8b91f7,0xAefCDA6b2cF4EcC7A7E07099C79a729a7c8b91f7,0xAefCDA6b2cF4EcC7A7E07099C79a729a7c8b91f7,0x06a559acEDE9E7872dE280E6b8545Ff5c01c62ab,0x06a559acEDE9E7872dE280E6b8545Ff5c01c62ab,0x06a559acEDE9E7872dE280E6b8545Ff5c01c62ab,0x06a559acEDE9E7872dE280E6b8545Ff5c01c62ab,0x06a559acEDE9E7872dE280E6b8545Ff5c01c62ab,0x06a559acEDE9E7872dE280E6b8545Ff5c01c62ab,0x06a559acEDE9E7872dE280E6b8545Ff5c01c62ab,0x06a559acEDE9E7872dE280E6b8545Ff5c01c62ab,0x06a559acEDE9E7872dE280E6b8545Ff5c01c62ab,0xd17a9B2213A8D32145A3b278e5F7CeF22D670c42,0xd17a9B2213A8D32145A3b278e5F7CeF22D670c42,0xd17a9B2213A8D32145A3b278e5F7CeF22D670c42,0x9643af2a187d93fbE2a95B609382AbDaEBa3Ed86,0x9643af2a187d93fbE2a95B609382AbDaEBa3Ed86,0x9643af2a187d93fbE2a95B609382AbDaEBa3Ed86,0x9643af2a187d93fbE2a95B609382AbDaEBa3Ed86,0x9643af2a187d93fbE2a95B609382AbDaEBa3Ed86,0x9643af2a187d93fbE2a95B609382AbDaEBa3Ed86,0x9643af2a187d93fbE2a95B609382AbDaEBa3Ed86,0x9643af2a187d93fbE2a95B609382AbDaEBa3Ed86,0x9643af2a187d93fbE2a95B609382AbDaEBa3Ed86,0x9643af2a187d93fbE2a95B609382AbDaEBa3Ed86,0x3EA8422E956AFEB32C9D9638F5FB04BAdbe09bc1,0x01aC84081621568230be12b4276b92d07d584433,0x01aC84081621568230be12b4276b92d07d584433,0x01aC84081621568230be12b4276b92d07d584433,0x01aC84081621568230be12b4276b92d07d584433,0x01aC84081621568230be12b4276b92d07d584433,0x01aC84081621568230be12b4276b92d07d584433,0x01aC84081621568230be12b4276b92d07d584433,0x01aC84081621568230be12b4276b92d07d584433,0x01aC84081621568230be12b4276b92d07d584433,0x01aC84081621568230be12b4276b92d07d584433,0x21A9062bB9Dd238e200bd2499F2D9549c8C4cAF5,0x21A9062bB9Dd238e200bd2499F2D9549c8C4cAF5,0xe8a718296Edcd56132A2de6045965dDDA8f7176B,0xD3E570C52Fe8B3AbB7f4dC23D9A26eFb12909EfA,0x210635Cc96b9bb56cc9293979dF460212bc5F113,0x194183e414Bbd0C4074A1d08f392cA998b49c3F3,0x194183e414Bbd0C4074A1d08f392cA998b49c3F3,0x87828a9454d1C8CEB58eAcBCCcE91Bb02c423329,0x87828a9454d1C8CEB58eAcBCCcE91Bb02c423329,0x87828a9454d1C8CEB58eAcBCCcE91Bb02c423329,0x87828a9454d1C8CEB58eAcBCCcE91Bb02c423329,0x87828a9454d1C8CEB58eAcBCCcE91Bb02c423329,0x87828a9454d1C8CEB58eAcBCCcE91Bb02c423329,0x87828a9454d1C8CEB58eAcBCCcE91Bb02c423329,0x87828a9454d1C8CEB58eAcBCCcE91Bb02c423329,0x87828a9454d1C8CEB58eAcBCCcE91Bb02c423329,0x87828a9454d1C8CEB58eAcBCCcE91Bb02c423329,0x1c1BE57d27B7B5a697470F1F6F7DFCF38ee5CABE,0x1c1BE57d27B7B5a697470F1F6F7DFCF38ee5CABE,0x1c1BE57d27B7B5a697470F1F6F7DFCF38ee5CABE,0x1c1BE57d27B7B5a697470F1F6F7DFCF38ee5CABE,0x1c1BE57d27B7B5a697470F1F6F7DFCF38ee5CABE,0x1c1BE57d27B7B5a697470F1F6F7DFCF38ee5CABE,0x1c1BE57d27B7B5a697470F1F6F7DFCF38ee5CABE,0x1c1BE57d27B7B5a697470F1F6F7DFCF38ee5CABE,0x1c1BE57d27B7B5a697470F1F6F7DFCF38ee5CABE,0x1c1BE57d27B7B5a697470F1F6F7DFCF38ee5CABE,0xd0118B21a632615d899b02E8472E9457DD98062C,0xd0118B21a632615d899b02E8472E9457DD98062C,0xd0118B21a632615d899b02E8472E9457DD98062C,0xd0118B21a632615d899b02E8472E9457DD98062C,0xd0118B21a632615d899b02E8472E9457DD98062C,0xd0118B21a632615d899b02E8472E9457DD98062C,0xd0118B21a632615d899b02E8472E9457DD98062C,0xd0118B21a632615d899b02E8472E9457DD98062C,0xd0118B21a632615d899b02E8472E9457DD98062C,0xd0118B21a632615d899b02E8472E9457DD98062C,0xc1deEA95Ed5d402d052FA169dF008Faf54C3F837,0xc1deEA95Ed5d402d052FA169dF008Faf54C3F837,0xc1deEA95Ed5d402d052FA169dF008Faf54C3F837,0x3cbAee4F65B64082FD3a5B0D78638Ee11A29A31A,0x3cbAee4F65B64082FD3a5B0D78638Ee11A29A31A,0x3cbAee4F65B64082FD3a5B0D78638Ee11A29A31A,0x3cbAee4F65B64082FD3a5B0D78638Ee11A29A31A,0x3cbAee4F65B64082FD3a5B0D78638Ee11A29A31A];
        for(uint i=0;i<198;i++){
            lot0.indexedTickets[lot0.tickets[i]].push(i);
        }
        lot0.counter = Counters.Counter(198);
        
        Lottery storage lot1 = lotteries.push();
        lot1.spaceId = 0;
        lot1.creator = 0x830732Ee350fBaB3A7C322a695f47dc26778F60d;
        lot1.tokenAddr = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        lot1.pool = 1000000000000000000000;
        lot1.maxTickets = 1;
        lot1.winners = 0;
        lot1.start = 1670059244;
        lot1.end = 1671580800;
        lot1.requireSig = true;
        lot1.tickets = [0x3cbAee4F65B64082FD3a5B0D78638Ee11A29A31A,0xCE67B694bC268E7D9431e658A149657d46F80387,0x04a7CD054708F6D3a45994B957bE91ac9e34A687,0x37b3cE4eE95758e41B0E73EA3088eA9c3FdaCd32,0x24e972604cAF279f0aD9e4AbA677fA90c806b310,0x32573ec9734A1054cd0E35F0e28314e688089138,0x29dBC979b45B2F45B8BB41f612f80DCD8B2ef446,0xD3E570C52Fe8B3AbB7f4dC23D9A26eFb12909EfA,0xcf854C64d51FAcb63E052a1D2286Bb072D14913f,0x755309E7A48B97c9a2Ba87661A75B26df8431Ec2,0x21A9062bB9Dd238e200bd2499F2D9549c8C4cAF5,0x86c16F44BC75851a9E2E16e28366aDD78169fEA9,0x06a559acEDE9E7872dE280E6b8545Ff5c01c62ab,0x0a3C464FFD7458C5f4EB09a314A00623327957B8,0xeFF1105c656e72903Da56B004e89aC0F19b35c20,0x112D960C88de18482C5f4069c0286a5a57Bab086,0x46c2e6EFCeb9B4D7F92e300B8E0580D1943CE29B,0xd0118B21a632615d899b02E8472E9457DD98062C,0x01aC84081621568230be12b4276b92d07d584433,0xfefE83C39cEeE44F799068DCac8755D1D89358D9,0xFACb9eE3931231c4AD49787605d0d8637DC21133,0xAefCDA6b2cF4EcC7A7E07099C79a729a7c8b91f7,0x72D6960AAe3C90e2de304f6fb89263a7FCca14bB,0xDF55bBE2e152E55644C531eCf8697752BcCdb0C0,0x11217Bf4Da72c7b4425a83B4736699eEc7444Ec3,0xd438c8A16ec89a6492D6753f0C2735668e1db5Da,0xC81082690EDC8CDE6D83a7549aa6a74534305372,0xc1deEA95Ed5d402d052FA169dF008Faf54C3F837,0xd17a9B2213A8D32145A3b278e5F7CeF22D670c42,0x5dAb66Cddb79771Ae34F4EaaccBFe1898793d50f,0x5C36436eb678cEbBF2f77Aa52F8310141931D984,0xe078E67186C734CB06DC661Bc32A29F2E4626794,0x3D6db46E3A98F1D996aeAc9bbfBa570D0a60b4F7,0x9643af2a187d93fbE2a95B609382AbDaEBa3Ed86,0x28B07D5bf8c8205b0bF064A5dF5F24bB3B182879,0x87828a9454d1C8CEB58eAcBCCcE91Bb02c423329,0xd31A84c20bc430aD75E6a1903E7dDbee52211072,0x3EA8422E956AFEB32C9D9638F5FB04BAdbe09bc1,0x194183e414Bbd0C4074A1d08f392cA998b49c3F3,0x83a27BE9bc9c98A6Cd504570B4fa1899ae09F95f,0xDCFF316Bcda6674672e6C21A32496Ac61D3B12a0,0xe8a718296Edcd56132A2de6045965dDDA8f7176B,0x6c0cafe6165D1A37659B6f9728dE30969C35cbF2,0x96539455E49b8DE5738f85C2347cf7955775f502,0x102da0207BA3e1b18FcC826Fde188a133e0d27d4,0x8202F1fF3A94e199d970919d8D71Ffb434b6F627];
        for(uint i=0;i<45;i++){
            lot1.indexedTickets[lot1.tickets[i]].push(i);
        }
        lot1.counter = Counters.Counter(45);
        
        Lottery storage lot2 = lotteries.push();
        lot2.spaceId = 0;
        lot2.creator = 0x830732Ee350fBaB3A7C322a695f47dc26778F60d;
        lot2.tokenAddr = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        lot2.pool = 2000000000000000000000;
        lot2.maxTickets = 1;
        lot2.winners = 0;
        lot2.start = 1670059244;
        lot2.end = 1671580800;
        lot2.requireSig = true;
        lot2.tickets = [0x3cbAee4F65B64082FD3a5B0D78638Ee11A29A31A,0xd0118B21a632615d899b02E8472E9457DD98062C,0xCE67B694bC268E7D9431e658A149657d46F80387,0x06a559acEDE9E7872dE280E6b8545Ff5c01c62ab,0x3D6db46E3A98F1D996aeAc9bbfBa570D0a60b4F7,0xd31A84c20bc430aD75E6a1903E7dDbee52211072,0x01aC84081621568230be12b4276b92d07d584433,0x04a7CD054708F6D3a45994B957bE91ac9e34A687,0x83a27BE9bc9c98A6Cd504570B4fa1899ae09F95f,0xD3E570C52Fe8B3AbB7f4dC23D9A26eFb12909EfA,0xcf854C64d51FAcb63E052a1D2286Bb072D14913f,0x46c2e6EFCeb9B4D7F92e300B8E0580D1943CE29B,0x755309E7A48B97c9a2Ba87661A75B26df8431Ec2,0xDF55bBE2e152E55644C531eCf8697752BcCdb0C0];
        for(uint i=0;i<14;i++){
            lot2.indexedTickets[lot2.tickets[i]].push(i);
        }
        lot2.counter = Counters.Counter(14);
    }

    function create(
        uint spaceId,
        address tokenAddr,
        uint256 maxTickets,
        uint256 ticketPrice,
        uint256[] memory winnerRatios,
        uint32 winners,
        uint256 start,
        uint256 end,
        bool requireSig
    ) public {
        require(end > start && end > block.timestamp, "invalid time");
        require(maxTickets > 0, "invalid maxTickets");
        require(winnerRatios.length == winners, "invalid winners");
        if (tokenAddr != address(0)) {
            IERC20 token = IERC20(tokenAddr);
            require(token.totalSupply() > 0, "invalid token");
        }else{
            require(ticketPrice == 0, "invalid token");
        }

        uint256 ratioSum;
        for (uint256 i = 0; i < winners; i++) {
            ratioSum += winnerRatios[i];
        }
        require(ratioSum <= 100, "invalid ratio");

        Lottery storage lot = lotteries.push();
        lot.spaceId = spaceId;
        lot.creator = msg.sender;
        lot.tokenAddr = tokenAddr;
        lot.maxTickets = maxTickets;
        lot.ticketPrice = ticketPrice;
        lot.winnerRatios = winnerRatios;
        lot.winners = winners;
        lot.start = start;
        lot.end = end;
        lot.requireSig = requireSig;

        emit CreateLottery(lotteries.length - 1);
    }

    function fund(uint256 lotId, uint256 amount) public {
        Lottery storage lot = lotteries[lotId];
        require(lot.end > block.timestamp, "invalid time");
        require(lot.tokenAddr != address(0), "invalid token");
        IERC20 token = IERC20(lot.tokenAddr);
        token.transferFrom(msg.sender, address(this), amount);
        lot.pool += amount;

        emit Fund(lotId, amount);
    }

    function join(uint256 lotId, uint256 quantity, bytes memory sig) public {
        Lottery storage lot = lotteries[lotId];
        require(
            lot.start <= block.timestamp && lot.end > block.timestamp,
            "invalid time"
        );
        if(lot.requireSig){
            bytes32 message = keccak256(abi.encodePacked(lotId, msg.sender));
            require(spaceRegistration.verifySignature(lot.spaceId, message, sig), "Sig invalid");
        }

        uint256 currentLen = lot.indexedTickets[msg.sender].length;
        require(
            quantity > 0 && currentLen + quantity <= lot.maxTickets,
            "invalid quantity"
        );

        if(lot.tokenAddr != address(0) && lot.ticketPrice > 0){
            uint256 totalPrice = quantity * lot.ticketPrice;
            IERC20 token = IERC20(lot.tokenAddr);
            token.transferFrom(msg.sender, address(this), totalPrice);
            lot.pool += totalPrice;
            emit Fund(lotId, totalPrice);
        }
        
        uint256[] memory buff = new uint256[](currentLen + quantity);
        // copy current tickets
        for (uint256 i = 0; i < currentLen; i++) {
            buff[i] = lot.indexedTickets[msg.sender][i];
        }
        // add new purchased tickets
        for (uint256 i = 0; i < quantity; i++) {
            buff[currentLen + i] = lot.counter.current();
            lot.tickets.push(msg.sender);
            lot.counter.increment();
        }

        lot.indexedTickets[msg.sender] = buff;
        emit Join(lotId, msg.sender, quantity);
    }

    function draw(uint256 lotId) public {
        Lottery storage lot = lotteries[lotId];
        require(block.timestamp > lot.end, "not available");
        require(lot.vrfRequestId == 0, "drawed");

        lot.vrfRequestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            lot.winners
        );

        s_requests[lot.vrfRequestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false,
            lotId: lotId
        });
        emit RequestSent(lotId);
    }

    function getWinners(uint256 lotId)
        public
        view
        returns (address[] memory result)
    {
        Lottery storage lot = lotteries[lotId];
        if(lot.winners==0){
            return result;
        }
        RequestStatus storage randomRequest = s_requests[lot.vrfRequestId];
        require(randomRequest.fulfilled, "no result");
        result = new address[](lot.winners);
        uint256 currentLen = lot.counter.current();
        for (uint256 i = 0; i < lot.winners; i++) {
            uint256 index = randomRequest.randomWords[i] % currentLen;
            for (uint256 j = 0; j < i; j++) {
                uint256[] storage indexedTickets = lot.indexedTickets[
                    result[j]
                ];
                for (
                    uint256 k = 0;
                    k < indexedTickets.length && indexedTickets[k] <= index;
                    k++
                ) {
                    ++index;
                }
            }

            result[i] = lot.tickets[index];
            currentLen -= lot.indexedTickets[result[i]].length;
        }

        return result;
    }

    function prize(uint256 lotId) public view returns (uint256) {
        Lottery storage lot = lotteries[lotId];
        if (lot.indexedTickets[msg.sender].length == 0 || lot.tokenAddr == address(0) || lot.pool == 0) return 0;
        address[] memory winners = getWinners(lotId);
        uint256 winnerPrizes;
        uint256 winnerTickets;
        for (uint256 i = 0; i < winners.length; i++) {
            if (msg.sender == winners[i]) {
                /**
                * if winner => return
                */
                return (lot.pool * lot.winnerRatios[i]) / 100;
            } else {
                winnerTickets += lot.indexedTickets[winners[i]].length;
                winnerPrizes += (lot.pool * lot.winnerRatios[i]) / 100;
            }
        }
        return
            ((lot.pool - winnerPrizes) *
                lot.indexedTickets[msg.sender].length) /
            (lot.tickets.length - winnerTickets);
    }

    function claim(uint256 lotId) public nonReentrant {
        Lottery storage lot = lotteries[lotId];
        require(
            lot.indexedTickets[msg.sender].length > 0 &&
                !lot.claimedAddrs[msg.sender],
            "invalid user"
        );

        uint256 prizeVal = prize(lotId);
        require(prizeVal > 0 && lot.pool - lot.claimed > prizeVal, "not claimable");

        IERC20 token = IERC20(lot.tokenAddr);
        token.transfer(msg.sender, prizeVal);
        lot.claimed += prizeVal;
        lot.claimedAddrs[msg.sender] = true;

        emit Claimed(lotId, msg.sender);
    }

    function withdraw(uint256 lotId) public onlyOwner {
        Lottery storage lot = lotteries[lotId];
        require(lot.pool - lot.claimed > 0 , "dry");
        require(block.timestamp > lot.end + life || lot.tokenAddr == address(0) , "not available");
        IERC20 token = IERC20(lot.tokenAddr);
        token.transfer(msg.sender, lot.pool - lot.claimed);
        lot.claimed = lot.pool;
    }
    
    function setLife(uint256 _life) external onlyOwner {
        life = (_life);
    }

    function setKeyHash(bytes32 _keyHash) public onlyOwner{
        keyHash = _keyHash;
    }

    function setSpaceRegistration(address addr) public onlyOwner{
        spaceRegistration = ISpaceRegistration(addr);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        require(!s_requests[_requestId].fulfilled, "fulfilled");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(s_requests[_requestId].lotId, _randomWords);
    }

    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function tickets(
        uint256 lotId,
        uint256 cursor,
        uint256 length
    ) public view returns (address[] memory) {
        Lottery storage lot = lotteries[lotId];
        require(cursor + length <= lot.counter.current(), "invalid len");

        address[] memory res = new address[](length);
        for (uint256 i = cursor; i < cursor + length; i++) {
            res[i] = lot.tickets[i];
        }
        return res;
    }

    function ticketsByUser(uint256 lotId, address addr)
        public
        view
        returns (uint256[] memory)
    {
        return lotteries[lotId].indexedTickets[addr];
    }

    function lottery(uint256 lotId)
        public
        view
        returns (
            uint spaceId,
            address tokenAddr,
            uint256 pool,
            uint256 maxTickets,
            uint256 ticketPrice,
            uint256[] memory winnerRatio,
            uint256 vrfRequestId,
            uint256 start,
            uint256 end,
            uint256 totalTickets,
            uint256 claimed,
            bool requireSig
        )
    {
        Lottery storage lot = lotteries[lotId];
        RequestStatus storage randomRequest = s_requests[lot.vrfRequestId];
        return (
            lot.spaceId,
            lot.tokenAddr,
            lot.pool,
            lot.maxTickets,
            lot.ticketPrice,
            lot.winnerRatios,
            lot.vrfRequestId,
            lot.start,
            lot.end,
            lot.counter.current(),
            lot.claimed,
            lot.requireSig
        );
    }

}