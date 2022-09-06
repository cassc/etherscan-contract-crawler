// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract WeirdPeople is ERC721AQueryable, Ownable, ReentrancyGuard {

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
        _mint(0x9fc86fA1F9C3cDA8dd94011E54e29106b676bE10, 8);
_mint(0x2420ac35FE78a6eB5B2648354c06076a8b7A1d42, 7);
_mint(0xB2C5B87E865eB9bBF93D369abae565A47aEB1394, 7);
_mint(0xdD33413A504Ab2Fa693a111dc922E5e17496552C, 7);
_mint(0x3eFf592BA8A49f915e38B7274ea4Ff0AAbac8EfF, 6);
_mint(0x2b81Eaac4936c5413BbD8536D6998E73E631bF53, 5);
_mint(0x9Baf7C87825e382408a5C17D36af48d3c8A4756B, 5);
_mint(0xA101064ebF57549e47E955c746744342BdF613B5, 5);
_mint(0xD4F6396155DFFb7D37e696320B7e886B22e5fc97, 5);
_mint(0x35c28F43Ec7890E637F17BF34b379c422f5693D9, 4);
_mint(0x3f44E32E288D3E3B31EC1E7332940729A6eceB33, 4);
_mint(0xBF6265A661a9024591227dd199FAc4347107Dd8B, 4);
_mint(0x06c6a7c0Bc849D795dBDEfdc48007F4f53845878, 3);
_mint(0x24e90090DeDA09E90BC20d6448799fcC963310b5, 3);
_mint(0x2cF41f874F4b60d8792aE16E5e343eDe2f574353, 3);
_mint(0x3c4cF64127503E3B17ab4741A30352E712D71Bd4, 3);
_mint(0x62cDf35D06850F4Ea008AE5a5D1965670eA56e41, 3);
_mint(0x689A19F57077F682A1D7cc19D9066F1a834721a2, 3);
_mint(0x6f99c30482601E8Ad021c7594B372A58291Ede60, 3);
_mint(0xc2685c074f2fcF355Bcae79648A3e3B2CF36B1e9, 3);
_mint(0xE2a331eE86747E7C345fe299522f7f14174B432B, 3);
_mint(0xedDeF7bB3989e38A72B0A8881Cb83B038D32669a, 3);
_mint(0xff7469e42e1E0C20eA7C38c6Bd189afa009D977b, 3);
_mint(0x0450cA1Cf6014aa0B9e4a0EA09B7363F6167B928, 2);
_mint(0x08492eaa6301b71aaBE8c269F03663b6B6a2d116, 2);
_mint(0x0D3f5a7A1Ee78E743e25C18e66942FcBcD84CcAD, 2);
_mint(0x12B6B076B169ca1d25B7aC5Dec436EA8067b0CF6, 2);
_mint(0x26EA7Dab466F2C86Eb6e9F3b0597F1C29aD87CfD, 2);
_mint(0x286Fb9Ff6f7FCC5b597C3ca88049A7e5c765aa4E, 2);
_mint(0x2d197b021DA9Ae657Ebad44126b0C94eCE03F609, 2);
_mint(0x33FE07b9458D34F777b7207b301Df93CCC8dBA67, 2);
_mint(0x388671ECF45d7B9e6e3cBF499b5058E4c607B7cA, 2);
_mint(0x3FBbAF77bA1673E10391ED5906c8d8b70fF5A1D4, 2);
_mint(0x5236E9500b43c994bB9BbF15Cbb33b2B10F955Fa, 2);
_mint(0x62cDf35D06850F4Ea008AE5a5D1965670eA56e41, 2);
_mint(0x67123B8484A699c718c6cCBF6390f13053B37Ad7, 2);
_mint(0x67A76f74D2a671086fAdbD01EabeBb20FcA475D5, 2);
_mint(0x6ad5899088CA31F129E9B036De67D7b7DAecB63f, 2);
_mint(0x766d941b392DC415c7CeAC480632E4105fdDb0E1, 2);
_mint(0x79F67eE004F47c17A5fb5362801449282470e9C7, 2);
_mint(0x837c3C3c7A5bfD37cf6eeb02f9417652d7CAFA55, 2);
_mint(0x9d25b797fd0bA7081B910e6275510B62443d675E, 2);
_mint(0xadC49E2752eC6c5fF93D6184Ef5bD30D53960B68, 2);
_mint(0xb079f6e73386e868005F79CdB6Bb069846e0Dd47, 2);
_mint(0xB0c2dD382b1f86535FAd6feF8e5b834C1D452822, 2);
_mint(0xbf4936C0c19A3FCE25751Dcf4731A1C34a1Dc8bf, 2);
_mint(0xcd13252a6Fc5C4077aDd38cB40C88cc8cBb38984, 2);
_mint(0xD26047cF3Aa6691C0A9F5D34dD76b3dF55A3d61e, 2);
_mint(0xdc65b62A2E61500Dd9C6c07607E672D1820BEa6e, 2);
_mint(0xEAF6C384eBcD826DD6a5d8f305A40683A1cf77f0, 2);
_mint(0xfCD14bB8240D08d6edeF85e68FC1944b99C4278E, 2);
_mint(0x082293EcdDcb5f6eF9a8B98eB7caeFa240Ca1EDb, 1);
_mint(0x097AD0D9B8489A8bBf016DEd34FaBef2c53b7FAc, 1);
_mint(0x09b182dE117A174345182d4f80FCFf0510387fCC, 1);
_mint(0x09b6f9717E04224FB413e0ABa09ea72B7C0d313B, 1);
_mint(0x0D8990B77dcbcc05404dd4F1cA3145583C590211, 1);
_mint(0x15caBbbD0d6AC3C238BbC78a1AD3d8b65449CDF9, 1);
_mint(0x1A7EFeF04aEf0Ef44d8892fdC5dab9426f34e1ac, 1);
_mint(0x1d186Cf5DCf4D25C45Dff9eC707990De3114C5f6, 1);
_mint(0x1D87FC655c44Ae85Eaa15807ce00433B7F36933d, 1);
_mint(0x21cE8883cb29A23A676B6731d60D0eBC6d520aFE, 1);
_mint(0x257410d0293EE474e7ddD78C9ffD24c610765971, 1);
_mint(0x2A008289E9bcECe9a98F14348cbca2eee9056F53, 1);
_mint(0x2f14fBa7f3b90DAA8DE0f35DfE0c6859cBB0034a, 1);
_mint(0x41D7cFcC2477356beF5b185a925708945986Ab94, 1);
_mint(0x4a530Bb00FA38eb04BFda4231eAAB19c27d103DC, 1);
_mint(0x4d6De83df0B7Cb1b8A3790d9161595e56a277727, 1);
_mint(0x5213700Bb7780Cb8fae844f593e19021C9BE0CD2, 1);
_mint(0x5b0130ECdFB68858f48e4b29E913077E670a6BDB, 1);
_mint(0x6EEf09B526d883F98762a7005FABD2c800DfCA44, 1);
_mint(0x7cBeD430Cb3152E4fD0842Bd50747559Ec02ead5, 1);
_mint(0x80894C9C28918626DD9A2cAb6387cc032cC38d8D, 1);
_mint(0x88E5170938b6AA05EA600b765a76eFeC0C85D4a7, 1);
_mint(0x89969196621C8F4b5d56EC79D121E1d997946F31, 1);
_mint(0x8C5Dc519418E6eD2778DcacEE2BDAB3708B75E38, 1);
_mint(0x8D88E308FCc8a6508B562f0C82Bb70Ae0088A8ed, 1);
_mint(0xa73660448d30b1a14C15593f004ca2dF7A8De0F0, 1);
_mint(0xA756dD865616fa20c92Eb92d08991319ba3a670A, 1);
_mint(0xa7D0eD043d3d818BAc89E71Cd6df0Bb294343BeD, 1);
_mint(0xad82Ea28D703772239032191d0EC7a5F4DF4EDa9, 1);
_mint(0xBFE0339c79481125a902F54157D2Fbf01e305822, 1);
_mint(0xC12d71522c69d6C6cbD25532B1B0Fe0fFDB026A5, 1);
_mint(0xC92d20247a8B20E640d339428968b2501e579c7b, 1);
_mint(0xC980681605F611FF2F8c6B0a38347D9683238a3D, 1);
_mint(0xD3406DB640C81DEe26C31c6e6fd89441Ac9d2D21, 1);
_mint(0xD3A3EE6b6266850351f9E31979429C3fFD4Bf59c, 1);
_mint(0xd442BbF730e05b91cbFefD34b445B73478c89f8e, 1);
_mint(0xD5a76031EE8577e65C37c6891C637442A57A37c4, 1);
_mint(0xD8dBC8Db662B2712c5C9E1e66A961c427a81bE3d, 1);
_mint(0xDB4E64e615B46F9dA2c48e7444F45CC5754F823F, 1);
_mint(0xde4Df5BA7BD82FcF27338c5dED55164708F8E096, 1);
_mint(0xeb85C8353787bb1D2B975712bA478A4f8A2C65A7, 1);
_mint(0xF2C77a10e00AFB21CD0585aCF0c8c149a1379577, 1);
_mint(0xf2CD16e2E2F2D4E187F581ee51fbfc7B2A6b1bb4, 1);
_mint(0xf4cba90f9Dcfc99C8bA9395B22CfC8117213D298, 1);
_mint(0x05cB80Ce8A7858bc011b85D76f7Dbe2eE7D0A214, 100);

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
    address FOUNDER_WALLET = 0x4f5950bd06015E0420264D02655592016654845B;
    address FOUNDER_2_WALLET = 0x51fe02074535354C4013Fb00777e34C224ab8aB2;
    address DEVELOPER_1_WALLET = 0xCf0c4fc7420025dfC9Cbe94f3E31688F09517aB8;
    address ADVISOR_WALLET = 0x9025F0De302c257B9841EeE863C1577bA9f788B7;
    address COLLAB_WALLET = 0x8Df76ee3Dc67dc2724c8eEf609B2D25B6B136124;
    address TREASURY_WALLET = 0x05cB80Ce8A7858bc011b85D76f7Dbe2eE7D0A214;
    address STAFF_WALLET = 0xC3c10039655bba4891faA4bA5547F30830599c4B;

    // FULL WITHDRAW
    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "NO FUNDS AVAILABLE");
        payable(FOUNDER_WALLET).transfer((balance * 10)/100);
        payable(FOUNDER_2_WALLET).transfer((balance * 10)/100);
        payable(DEVELOPER_1_WALLET).transfer((balance * 10)/100);
        payable(ADVISOR_WALLET).transfer((balance * 10)/100);
        payable(COLLAB_WALLET).transfer((balance * 5)/100);
        payable(TREASURY_WALLET).transfer((balance * 50)/100);
        payable(STAFF_WALLET).transfer((balance * 5)/100);
    }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}