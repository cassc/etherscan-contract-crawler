// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract TheKindnessProject is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
        _mint(0x9eB95d2ce7c806472EfAfB89Fc1D03466Ef516Cd, 1);
        _mint(0x9eB95d2ce7c806472EfAfB89Fc1D03466Ef516Cd, 1);
        _mint(0x473e12B41bC13d3Ac98C4d06cD549Ba8a704dbf1, 1);
        _mint(0x473e12B41bC13d3Ac98C4d06cD549Ba8a704dbf1, 1);
        _mint(0xE2a331eE86747E7C345fe299522f7f14174B432B, 1);
        _mint(0xE2a331eE86747E7C345fe299522f7f14174B432B, 1);
        _mint(0xE2a331eE86747E7C345fe299522f7f14174B432B, 1);
        _mint(0xE2a331eE86747E7C345fe299522f7f14174B432B, 1);
        _mint(0x4ac72cf2C23A1e00AE49749671690b3ea6C7D46f, 1);
        _mint(0x4ac72cf2C23A1e00AE49749671690b3ea6C7D46f, 1);
        _mint(0xC0468030c9Dd632Daa52E2221797ccC8a3F43922, 1);
        _mint(0xC0468030c9Dd632Daa52E2221797ccC8a3F43922, 1);
        _mint(0x35c28F43Ec7890E637F17BF34b379c422f5693D9, 1);
        _mint(0x33FE07b9458D34F777b7207b301Df93CCC8dBA67, 1);
        _mint(0x275bf84b73150F484B394F55b7bbe8ECDB5DDF5D, 1);
        _mint(0xf188eFBf912279715E46a1bDB378b994B45cd795, 1);
        _mint(0x5fdb0Fdeee546e95C552B1A1521441d8662d4298, 1);
        _mint(0x39820ac459E8d7CA56EC94BF1D0A7bE4A68AE3c1, 1);
        _mint(0x8118Aa67142Cf63AD5e9f7F755FE3eFC5A8790B7, 1);
        _mint(0x618e3e5707f62993695D8e4347495bb4c38466C2, 1);
        _mint(0xDf788eB75553b29cAB1A318dee77bF59567C2009, 1);
        _mint(0x397cC92Da013952925851FeF9aA0AFef150E4D8C, 1);
        _mint(0x6741a17fD1DB0431ce018032f98a532128e819e5, 1);
        _mint(0x3eFf592BA8A49f915e38B7274ea4Ff0AAbac8EfF, 1);
        _mint(0x7a640B5945954e257aE9B941c756BB99f0911fCd, 1);
        _mint(0x8C5Dc519418E6eD2778DcacEE2BDAB3708B75E38, 1);
        _mint(0xB3Cc8d3510F16BcAa7F3fa7241Fef86A3e890C97, 1);
        _mint(0xE06246A845aDbFe14DB01C8006Bb23b28951e7d3, 1);
        _mint(0x32579EcC5dD1e5e641cf7B72cb0016093C6C7964, 1);
        _mint(0xc6C5891CE448dB3E4155de1A0d85107f0a8bc6e3, 1);
        _mint(0xEAF6C384eBcD826DD6a5d8f305A40683A1cf77f0, 1);
        _mint(0x1c2Bd0cC868A72b0E38eF5aa10288256Bc535bDF, 1);
        _mint(0x32579EcC5dD1e5e641cf7B72cb0016093C6C7964, 1);
        _mint(0x1D182535A587BcFCF064765f30ACeB78e481a7F3, 1);
        _mint(0x36aC62a67127a6013B3861c8c229B3fdE92E897A, 1);
        _mint(0xF1Fa0bb46cCe9dbA707e68CB64D2FB159Ec1fEE5, 1);
        _mint(0x275bf84b73150F484B394F55b7bbe8ECDB5DDF5D, 1);
        _mint(0x2A2a159a96912733E40BDD721d2533eF5931274f, 1);
        _mint(0xCFebf82E85aC212153c65bC1FC48d2E9d2369698, 1);
        _mint(0xE06246A845aDbFe14DB01C8006Bb23b28951e7d3, 1);
        _mint(0x3b7fD269a8df5805c1664D6AcA85569fcb51885E, 1);
        _mint(0xAc93FAabf714BaC62657513cA4dA1eB4ae03b2B5, 1);
        _mint(0xF1Fa0bb46cCe9dbA707e68CB64D2FB159Ec1fEE5, 1);
        _mint(0x397cC92Da013952925851FeF9aA0AFef150E4D8C, 1);
        _mint(0x2A2a159a96912733E40BDD721d2533eF5931274f, 1);
        _mint(0xCBc3762F96B39a8282891e2b3eE685474798cc38, 1);
        _mint(0x591631285F17e0e3aE23c2695b632575B2455A1C, 1);
        _mint(0x15aDC7569505c1bf800DaaCD17A516A827eFF7B6, 1);
        _mint(0x1D182535A587BcFCF064765f30ACeB78e481a7F3, 1);
        _mint(0x4ac72cf2C23A1e00AE49749671690b3ea6C7D46f, 1);
        _mint(0x397cC92Da013952925851FeF9aA0AFef150E4D8C, 1);
        _mint(0x5AC784a8c43de48AfeCb5b6e20FAfF9ad2d2Ac10, 1);
        _mint(0xE2a331eE86747E7C345fe299522f7f14174B432B, 1);
        _mint(0x35c28F43Ec7890E637F17BF34b379c422f5693D9, 1);
        _mint(0x27f1d47abf7f4A21d6D97c30cfE7B08D4BFF30b4, 1);
        _mint(0x5e2979395b7C2F3275CeA442818Fc888215c5caf, 6); // insert TKP wallet for shelby, shan, night_owl, jamie, squishi, rekt
        _mint(0x149446A2c24Eb2faff15F3732f68eb9cd4362274, 1);
        _mint(0xF5DFdB8E86C55ca852a0c5b45F19E12be4B9f141, 1);
        _mint(0x591631285F17e0e3aE23c2695b632575B2455A1C, 2);
        _mint(0xCFebf82E85aC212153c65bC1FC48d2E9d2369698, 6);
        _mint(0x149446A2c24Eb2faff15F3732f68eb9cd4362274, 2);
        _mint(0xAc93FAabf714BaC62657513cA4dA1eB4ae03b2B5, 3);
        _mint(0x4ac72cf2C23A1e00AE49749671690b3ea6C7D46f, 3);
        _mint(0x35c28F43Ec7890E637F17BF34b379c422f5693D9, 1);
        _mint(0x36aC62a67127a6013B3861c8c229B3fdE92E897A, 2);
        _mint(0xEAF6C384eBcD826DD6a5d8f305A40683A1cf77f0, 5);
        _mint(0xF1Fa0bb46cCe9dbA707e68CB64D2FB159Ec1fEE5, 4);
        _mint(0xCBc3762F96B39a8282891e2b3eE685474798cc38, 1);
        _mint(0x2d197b021DA9Ae657Ebad44126b0C94eCE03F609, 1);
        _mint(0x397cC92Da013952925851FeF9aA0AFef150E4D8C, 15);
        _mint(0xdC93d75149756B060c431D9DBAa937Da67BDd6E7, 1);
        _mint(0x8533CF1CA87fa5CFF905BeBa585D1022B49Be828, 3);
        _mint(0xF79b434873b2762307099666C63D4c62b014C51E, 2);
        _mint(0x8e28e10660f9998472e61A5e8447452E7c80a94a, 1);
        _mint(0x772D6518C54eF2eB554fCeD24BbD705A5A1657e6, 1);
        _mint(0x1D915159Aeee1c9d71B4bE758301938B26be0966, 6);
        _mint(0x15aDC7569505c1bf800DaaCD17A516A827eFF7B6, 4);
        _mint(0x4E9edD87ADd0694398c430981d22fC17E39DFd6d, 1);
        _mint(0xB3Cc8d3510F16BcAa7F3fa7241Fef86A3e890C97, 4);
        _mint(0x1D182535A587BcFCF064765f30ACeB78e481a7F3, 6);
        _mint(0x67BE56FD6CE9703D2A3F24dB6B9b5F1fbd1e4386, 1);
        _mint(0xB7204e8B76900f69d8273B0b217700d2C525010D, 1);
        _mint(0x686CB9D88719E85aCA606797743A6cc0F7343d31, 1);
        _mint(0xc62E76a6Bb03E76b3152413C2B018752f8BE7606, 2);
        _mint(0x6132524899AbBDC16B7bC0bbbF1Fea77B2668365, 3);
        _mint(0x9c173A6F2f827895eBFC7a0dE4e9F7aDd89eAeB0, 1);
        _mint(0xe09815159ba25902a341AF4E7D47bFEF1e8c836A, 1);
        _mint(0x56868e255834782581677b195eb79573fE62fd87, 1);
        _mint(0xac39eA2Fb4Ee4Bb20121508FA0551ca77DC78C33, 1);
        _mint(0x44218C637fcf1a1CFC40a348685BfCf01BacE31A, 1);
        _mint(0x03Bbd6F1A1a712fa3B3f47412C72A8A74E3339a7, 1);
        _mint(0x837c3C3c7A5bfD37cf6eeb02f9417652d7CAFA55, 1);
        _mint(0x56AD9625afbD5Cb2c460bc26b2abBBF21Fe75bdA, 2);
        _mint(0xe8484605fa0887717e558A417751e643abb34D12, 1);
        _mint(0x5a7590079B0BF746c424B62249e33f6248B8EB74, 2);
        _mint(0x4dc4C46Fc1842f45113aE473809D2e88d8396d10, 1);
        _mint(0xAfa9abc254754fF6324E96cd8621D56109AFFB26, 2);
        _mint(0x5AC784a8c43de48AfeCb5b6e20FAfF9ad2d2Ac10, 2);
        _mint(0x5C34E725CcA657F02C1D81fb16142F6F0067689b, 1);
        _mint(0xFb9fc9Be1b1ade3138563748Ec3F3A5b4B9967c3, 2);
        _mint(0xa432DC73ee0d60c193c543dE42B6ae1e195020Ee, 2);
        _mint(0xeD694487CcaC768b04aed34700de75f96D584930, 1);
        _mint(0x45Ca078E0cD881096815C8c1Ff8fc3F0BDe58442, 1);
        _mint(0xa888A01aBf17Cf1f88C0E1Ca13674fa9F93b96A9, 1);
        _mint(0x1dec784B6C854222Fc7b2155791ccdcFf3e33C07, 2);
        _mint(0x0108afDCDd4EA85d7FE5f7f529fF1093Cb4D2Dc6, 1);
        _mint(0x97522bE0e661e257788067C989651e7AeE3B9261, 1);
        _mint(0x5236E9500b43c994bB9BbF15Cbb33b2B10F955Fa, 2);
        _mint(0xb33511A04C80544f82291727a93FEfA61b2a90dB, 1);
        _mint(0x6200769A96CA7054EB34D77230D6747e6Ec89D95, 2);
        _mint(0xbC3613715492a94f76AaaB581DcdFe61D8858b4b, 2);
        _mint(0x5e07fB29aA7fB940188eF1654D13818Dbc5aFCd9, 2);
        _mint(0xDB4E64e615B46F9dA2c48e7444F45CC5754F823F, 2);
        _mint(0x489C6Ece59631F254d1f4fc7D9Ac62F44281bDdA, 1);
        _mint(0xdDC57D029146698D59f4c465062c9900beF7dCbc, 1);
        _mint(0xB195679e7dAd1D236877A0594Da0A502E714C161, 1);
        _mint(0x0848E42Eae131dba9E4811f4C51895A7BB0CCC77, 1);
        _mint(0xC45670a6DB970296AC056734407a0CEC2719C04d, 1);
        _mint(0x0318D1d44208c468A3410914f50883e55304d145, 1);
        _mint(0x2e5A28037Fa6426b240d607e953BdfF90fe4a596, 1);
        _mint(0xc9eE9Fe68074Be6b5FE1826b5B0618Ccbcbda442, 2);
        _mint(0x4A9e7dd5b5f2987B85e197504e05E90563d60DA7, 1);
        _mint(0x64C07077c0dB13Cbf038050742E847432eA9ca2D, 1);
        _mint(0x2074424E6328ba40CEeA2F029aEf2662eA09c858, 1);
        _mint(0xa99aB610b9Bbac986F30882d8Bb84E55e3faD690, 1);
        _mint(0x5fdb0Fdeee546e95C552B1A1521441d8662d4298, 1);
        _mint(0xEd5957c426D46b979455CdE5178352660232C4de, 3);
        _mint(0x723CBC55DFb0Acab5A2fc5CF63AE322251dcB714, 1);
        _mint(0x13683B385ae5EC93024aa30a72274b219FdC3686, 1);
        _mint(0x1b6db55C7aa95F74f38B27D50eAee75A6a27d631, 1);
        _mint(0x32ea0b9ad4CEFdf67D19E90a9Be1a3Dd1627EA3a, 1);
        _mint(0xC1Dc4CeeF628D3eb4527E211F7691430f6e7E63C, 2);
        _mint(0xE2a331eE86747E7C345fe299522f7f14174B432B, 4);
        _mint(0xa23B1c4070c8FC3a9Bf7CcFC0ce0670d04f5F563, 2);
        _mint(0xc87c526d655Dd29D7c411F307c5c390f4d0d1B6c, 1);
        _mint(0xf7F012DF63CC03A63154f1c73CfaB3B94AcA3F21, 7);
        _mint(0x07C42831b30c68824f261C61074aC13F8Aa885d3, 1);
        _mint(0xb53f2b60A7ec0144D2C7C8fDE65E292c750559e2, 2);
        _mint(0xB3f6702aBa5a9681d825851A50Abe0f592f2fc0B, 1);
        _mint(0xf4FED1aFabC2A8ce096C32Cd57Fd86584Be9a568, 1);
        _mint(0xe2935EFd678C474fFf00fa307Befd26c6E78A321, 1);
        _mint(0x2eDcd8AC3F770dA56bba4735eB9369609d82945f, 2);
        _mint(0x934cceb5A43cDa9Ef7B2d78c6EcDd7712c725a5B, 4);
        _mint(0x473e12B41bC13d3Ac98C4d06cD549Ba8a704dbf1, 2);
        _mint(0xe3C6E58095a2Eec9eBd088166D14e3d5Ae00D097, 1);
        _mint(0xE06246A845aDbFe14DB01C8006Bb23b28951e7d3, 1);
        _mint(0xD43eBA46E10c08640caA952AB6d4ef11136F418E, 1);
        _mint(0x8C5Dc519418E6eD2778DcacEE2BDAB3708B75E38, 1);
        _mint(0x84b68db24d112c05b380A491f3658230cB74ABD2, 1);
        _mint(0x47FE71D055B82B55c988DaF0D95d3C0B27c0cf01, 1);
        _mint(0xb7Ee3cd42A17a2Ecc6a50ca5Fd60f6F7451C7a86, 1);
        _mint(0xC0468030c9Dd632Daa52E2221797ccC8a3F43922, 1);
        _mint(0x2718f35e4d0c2343463B1c44d93EfAd4c82b602c, 1);
        _mint(0x275bf84b73150F484B394F55b7bbe8ECDB5DDF5D, 1);
        _mint(0xfF49e90FCFBcF3eaf9e4c16573796B7d7C6a7A63, 1);
        _mint(0x33FE07b9458D34F777b7207b301Df93CCC8dBA67, 2);
        _mint(0x1c2Bd0cC868A72b0E38eF5aa10288256Bc535bDF, 1);
        _mint(0x2A2a159a96912733E40BDD721d2533eF5931274f, 3);
        _mint(0xDf788eB75553b29cAB1A318dee77bF59567C2009, 3);
        _mint(0xA17EDC44dAEf27f8C32E85D33938ae7464eBb297, 1);
        _mint(0x5f6266B796750Dc142F3806fa1c1c8c8C8864c82, 3);
        _mint(0xc6C5891CE448dB3E4155de1A0d85107f0a8bc6e3, 4);
        _mint(0x93390A8E616Bbfd0ACa53e5Bd4fC17Cb81260AE4, 3);
        _mint(0xD4F6396155DFFb7D37e696320B7e886B22e5fc97, 2);
        _mint(0x4DA894138fD4436624Aa3FBf85800B16450255d8, 1);
        _mint(0x6f99c30482601E8Ad021c7594B372A58291Ede60, 1);
        _mint(0x0e9D65F662bc5DEe370985f246d0510beB52697F, 1);
        _mint(0x2420ac35FE78a6eB5B2648354c06076a8b7A1d42, 1);
        _mint(0x09E46e182AB77e2320e7346602EEc1B1517f4002, 1);
        _mint(0x32579EcC5dD1e5e641cf7B72cb0016093C6C7964, 3);
        _mint(0xADe6b319FD30ac88079cd23D8B6D2Ce14ed24374, 1);
        _mint(0x93D56eD4Dd2E9F3f914b06E9aA9DD18bac07c6bc, 1);
        _mint(0xE4F14360E315025d686c1F9F0a8BA253b86B1e77, 1);
        _mint(0x7a640B5945954e257aE9B941c756BB99f0911fCd, 1);
        _mint(0x415aE86583C7df490a6237B62A755b6B43a993da, 2);
        _mint(0x6741a17fD1DB0431ce018032f98a532128e819e5, 1);
        _mint(0x976A3f5cc8e9B0160037CE316C0eC425a7732a7F, 1);
        _mint(0xedDeF7bB3989e38A72B0A8881Cb83B038D32669a, 1);
        _mint(0x8E1169fC7394AABd6253439cC584703041baB21a, 1);
        _mint(0x6D0BfAe82ef52A24732668066B00403bab457a89, 1);
        _mint(0x6B8c6fafCa4E8BA7708C86160c9438008bFC3ae7, 1);
        _mint(0xA19bba98145dE26643e572403fcB929037D58741, 1);
        _mint(0x1Dc6fc17986aD018991ADC89aEDA01eC1a00E572, 1);
        _mint(0x11c8678135658637fc510757cB26a1dE551565C3, 1);
        _mint(0xCeBCA66fDE0d8E1bE874ccB45893F5B680082A8f, 2);
        _mint(0xeb4c5F9fe9D2600EBbf81Aae782061ae801f533B, 1);
        _mint(0xCf0c4fc7420025dfC9Cbe94f3E31688F09517aB8, 1);
        _mint(0xa55Ec6DcE8798b039c45dF60123C4752c1d45C99, 1);
        _mint(0x91d559Bfc9A543062c212C1F9f43aDCA56dD7C58, 1);
        _mint(0x723B53EFC9B5e76fA9Ddff2ed14Fbe572D212C7a, 1);
        _mint(0x1054dEd2Cb78F21228402Cd610378C4b63D4A36A, 1);
        _mint(0x1D87FC655c44Ae85Eaa15807ce00433B7F36933d, 1);
        _mint(0x7983f91136900a15A9CB19088E98BC6f28dC8d53, 1);
        _mint(0xb4Ac5D5B88b733E1bC2cD0713Bc279B495123736, 1);
        _mint(0xd9B078117e8baCD60A63f6F77cf2B8aEF6f8B98B, 1);
        _mint(0x3eFf592BA8A49f915e38B7274ea4Ff0AAbac8EfF, 2);
        _mint(0x311A8a670525cDbF9fbe6c832efd87D71a79a3e8, 1);
        _mint(0x40690b3DF2fA52396783a32Ff36ae7c3307cD323, 1);
      setCost(_cost);
      maxSupply = _maxSupply;
      setMaxMintAmountPerTx(_maxMintAmountPerTx);
      setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  function adminMint(address _destination, uint _quantity) external onlyOwner {
        require(_totalMinted() + _quantity <= maxSupply, "Not enough tokens left to mint");
        _mint(_destination, _quantity);
    }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }
  

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

// ======== WITHDRAW ========

    //ADDRESS LIST
    address TKP_WALLET = 0x4f5950bd06015E0420264D02655592016654845B;

    // FULL WITHDRAW
    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "NO FUNDS AVAILABLE");
        payable(TKP_WALLET).transfer((balance * 100)/100);
    }


  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}