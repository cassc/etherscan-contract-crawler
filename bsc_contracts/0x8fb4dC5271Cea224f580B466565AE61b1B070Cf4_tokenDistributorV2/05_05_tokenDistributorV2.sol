// Live deployment v3

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract tokenDistributorV2 is Ownable {
    using SafeMath for uint256;

    uint256 public maxUint256 = 2**256 - 1;

    uint256 private arrayLimit = 200;

    mapping(address => bool) public auth;

    modifier onlyAuth() {
         require(auth[_msgSender()] == true, "You are not authorised");  
        _;
    }

    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data);

    event Multisended(uint256 total, address tokenAddress);

    uint256 public nextDistribution;
    uint256 public epoch;
    uint256 public distributedTimes = 0;
    address public token = 0x79B2bc95344eFe31cb6a7B0Cf8A843a5eE125dFf;

    constructor() {
        epoch = 21600;
        nextDistribution = 1674388800;
        auth[msg.sender] = true;
        
    }



    uint256[] public allContributions =[300,300,300,200,300,600,300,300,
    400,300,300,300,300,245,300,300,300,150,300,76,300,300,230,300,600,
    300,300,300,300,200,416,300,122,300,300,300,300,600,300,300,300,300,
    300,300,300,300,300,300,300,300,300,300,300,300,300,90,300,100,300,
    300,300,600,300,75,500,300,200,300,300,300,245,300,300,300,300,57,450,
    300,300,300,300,300,300,300,300,300,300,300,25,300,300,190,300,300,300,
    300,300,300,300,579,300];

    address[] public allContributors = [0x01C4a52cd8B938c1EDf14D170aab94C939971F8a
    ,0x03226948641Ed06EFa965999931ede7E62bD980A,0x0394AE4eC2A79c22a03023aA97E744Bd1cb5E2ee,0x0397a369C467A60980C966a7F32810075C3ad922
    ,0x0533899655066ceaF79096682B8f58f905Bd9825,0x087C32a6da5F2086a31482f37531c63AbddC1A78,0x0C29E96A3bE670F8F30D944b75Ec9c8941Da0864
    ,0x0c7dEEDCf1A03E152665C5110e0277a2104dC2Ac,0x0c903443AE12a796D311d726Ec1368abEaB27D1D,0x1128473cfba4EAA11B4eB69418350a049e926225
    ,0x15A2dC3175d63D10cdeD8e69DCDC56d4960Bc107,0x16D088a79D7d36213618263184783fB4d6375e33,0x18833279f8d6c7Fc17faDAdEf31c3c3c166a8049
    ,0x1C2F5ec4239B2d1B10617f85AAFe9c047A52698C,0x1e2457f774E8c4c5913397C996393fE7575E8C13,0x1F45C27ADC6490392A06C516C5b2E945B7BEd5D9
    ,0x22ea48513d5cB8b76F524a35c75a14b38A16815A,0x279C3689d4277789027b931767107100459AF7D2,0x27a9B10213cD659467CDFfE2Eb8eBaedbdA3A57e
    ,0x29caA272B7733407b98958494fA8310ea4c10477,0x315E2990Bd3c49F706CDBEf61B8cF3FB1b1B67A9,0x316e19608542ffde812945d2052A37A97A2BdC75
    ,0x322BF9d11aB2A071737e00c7fC36d3a188bDB851,0x33d708908aF70BD27aFdAA02dC029901D3927098,0x34dc69A52E0c57C1F41dD1f78a91a2EC1fD068C9
    ,0x3a4Cc535FBe68E43a955d58a733f0Ea181322DC4,0x3DD911E88feBFcC2e66D4053D3a6EC05Fd84172C,0x45bff9C75CCc489f44e7BF146825C38cd8C33B6c
    ,0x475FE3a167Bf82EdC4fD49780Feb561132cc1b26,0x4B12435D43010972915cbf7dAafe0d1785160313,0x50CAcaB70fb7b1dD6c22Af542778892cF1d67930
    ,0x529a6F9Bbe4440C260D2bbDdeF9a690b28036dd8,0x5473DdAC2EBC5044aD6727201BF863C1D93B0986,0x562eD81E568d860d2B7Ce395a6ae364398e2A100
    ,0x5826914A6223053038328ab3bc7CEB64db04DDc4,0x582C35A77CF0c4726D433e9AC83db858893FF718,0x58C0aB1D5b44B9eED0F6F7a0A9Af90BF00c4A023
    ,0x58D223Af23A8f824819467C2Be0Bd8f3726D3259,0x5A103D25342479271cEDf4E3a682B6357323fA06,0x5acd29efdaC786d4f5D9797158E42D2574F0d76E
    ,0x5BB6B21D3d994322AB12Bf0b0d5B9Da49fA8d181,0x5c3C1905c625723D097A12034048d0dbb20697f8,0x5c994Ebbd45599D9A89fC0919666Fb5A60Ac38E1
    ,0x5d166646411D0D0a0a4AC01C4596f8DF2d5C781a,0x5e88209d620DB0F9E2FBBE17B41689c4b8a4348D,0x5FCB7206Ba4a2D8A563f0628E2342a0E712C156c
    ,0x60Ae5c0B5EA046ABAbB6C96bfed55A48C0642d89,0x63F06788670D8FE1e8994f88029b611B7A63821A,0x64a05b7a0F4e20745ea270783AF370D76A20537c
    ,0x67F084CFBb5f74974De0BC973AeF5b21cF641ae4,0x6bC3372488222a7Cdc225f7a356B0B7CAaEA54AC,0x6f3EA6E39097088c878415491755Adf6e29Fd064
    ,0x70537A25588b8E99a9a0D984566Da4F8Fc11841B,0x733b2d8E1714860D83Cb335f8ca59baEa148dde0,0x734dFEeAE96348F563e6c7012D0791Cd5ce0A1a1
    ,0x739f72a8196e1f4decE11C225345853e986048AC,0x74945438750F88BC6546aE49D6D395F63Fe122cC,0x7Cd857890d292f745bF87b00D2618A3FaB552349
    ,0x827d9B45ca1A7470Bd6f457cCF00DD48c17b1154,0x87e802D3De874d001241e6eD5Dea0F53b1117fbA,0x89FCc63AA4B651E4641e8112ef8BdCB488fE5439
    ,0x8a6ab47B1B794275c9e4D931e1F096DE117D775C,0x9112Df90a90Cff8eD8A3f094061B88a9d68B8381,0x916150ed15584B0e50091e97f8B0B89134D11D21
    ,0x91A109764c56e06cB069fd2Da655D1B54D42035D,0x923df95b648D338a654B8236204190c3EcA3ce10,0x92e3776Bf70eFdfe1C63D6D09fb32c5331F83700
    ,0x97288D6Da0afD7f4FbFF9Ced27D8737e49a20658,0x9a3f28AABeDae8717f40e6e1247388E229C8F979,0x9b312Be1de46EeDeF2076eA476B0592f1cCea0a6
    ,0x9C3Ca672Ef6Bb57e0F1e6955a7A2C9244E2c717b,0x9F60eD84490ECDa628834D5Fa674172dbb298BAa,0xa326B41FA576376e6B9aa5802b8EC91Cb9Fe12e0
    ,0xA81599Eac76045fce181Ae0D83A5843C39867AD4,0xa88361D2c0645F5d8Dd3Be72777a565059FBb139,0xAc705a595b11D6Bafd0168731F963A0aF1fF487d
    ,0xaf75df9cD0720aD9dfa49DD21EE7b81bD102c2E3,0xB16A140D88FCFc1ec3EbA07EA19eBBFA75d6f5Dc,0xB27Bab5009F7707339c1a9e4eD8A51003dbfA723
    ,0xb829a643bca5dF17fbE4BA2551a9Cf6E72A122eB,0xb905fC3913252E4C890a7BfbcBb51b53Ed667B55,0xb94f268D41FD1261545d67cD157f23E8b125E253
    ,0xbBf3B586206e49366d59454caD127f4aCdF57309,0xbcC66fcCce62b1Da1E7F38E1b7A900d7Abb438E8,0xBf982f06f9282DCE1621f49C8D282eb257e24198
    ,0xc0a9F8AEf993E72A176eDe5D9A8f6336C42e94F2,0xc0E27FABd50D33169aA3AE0F5b6997b92BFdEa6b,0xc52966af2B94565c6b1bAdAE86903D9C19CFB5C7
    ,0xc8a673B55999De446F08aB5D1968692E242d2B45,0xc90B206742426B419C2b2D26FE71C2a1dE91471e,0xd072674B0c218EFc6f6D5972563ccDfbf78e2eFe
    ,0xD27F291C045ff795F7c1A0eFf1989c3e6c3d7299,0xd31Ec37A948CE8af492e6070d97EbA9fC81a3be7,0xD42da3764E96a10246B91BB2e53B7d903c9fA733
    ,0xdf403EDF2797f3b616f65F7E12d8F4937fd2D347,0xE0d63bc8f8525da96b65Dd46e618fC69baFa97a8,0xe0Ff5F84b877923b938F44bef90D25fA786d5eef
    ,0xe1aC57d1eCb0dceAFCbBeE3B8C90DDE1530D8933,0xe662c4D0B3173837153CD11754696aF4b888c373,0xF0A20278A340420F0330c3E0d63Be54b5C88eCA0
    ,0xf54BBf4E053b097966fFbB99057F94a248563465];

    receive() external payable {}

  function setAuth(address _auth) public onlyOwner {
    auth[_auth] = true;
  }  
    function getArrayLimit() public view returns(uint256) {
        return arrayLimit;
    }

    function setArrayLimit(uint256 _newLimit) public onlyOwner {
        require(_newLimit != 0);
        arrayLimit = _newLimit;
    }


    function setNextDistribution(uint256 _nextDistribution) external onlyOwner {
        nextDistribution = _nextDistribution;

    }

    function runContriBution() external onlyAuth {
        require(block.timestamp > nextDistribution, "too early");
        address[] memory _contributors = allContributors;
        uint256[] memory _balances = allContributions;
        uint256 total = 0;
        require(_contributors.length <= getArrayLimit(),"Array length exceeds limit");
        require(_contributors.length == _balances.length,"Array length mismatch");
        IERC20 erc20token = IERC20(token);

        for (uint8 i = 0; i < _contributors.length; i++) {
            erc20token.transfer( _contributors[i], (_balances[i] * 1e18)/5);
            total += (_balances[i]  * 1e18)/5;
        }

        distributedTimes = distributedTimes + 1;
        nextDistribution = nextDistribution + epoch;
        emit Multisended(total, token);
    }

    function getTotalContributions() public view returns (uint256) {
        uint256 sum = 0;
        for (uint i = 0; i < allContributions.length; i++) {
            sum += allContributions[i];
        }
        return sum;
    }

    function findAddressIndex(address _address) internal view returns (uint256) {
        for (uint i = 0; i < allContributors.length; i++) {
            if (allContributors[i] == _address) {
                return uint256(i);
            }
        }
        return maxUint256;
    }

    function returnContribution(address _address) public view returns (uint256) {
           uint256 indexContributor = findAddressIndex(_address);
                      if (indexContributor != maxUint256) {
                return allContributions[indexContributor];
            }
            return 0;
    }

    // to interact with other contracts
    function sendCustomTransaction(address target, uint value, string memory signature, bytes memory data) public payable onlyOwner returns (bytes memory)  {
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data));
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data);

        return returnData;
    }

}