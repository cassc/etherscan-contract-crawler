// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

string constant ErrInvalidLength = 'invalid length of nonces';
string constant ErrInvalidMintable = 'invalid mintable contract address';
string constant ErrInvalidNonceAddress = 'invalid nonce to address';
string constant ErrInvalidSigner = 'invalid signer address';
string constant ErrInvalidTime = 'did not mint within timeframe';
string constant ErrInvalidURI = 'no uri found for tokenID';
string constant ErrLockedProperty = 'contract property is locked';
string constant ErrNotEnoughValue = 'not enough value';
string constant ErrNotSigner = 'invalid signature signer';
string constant ErrNotTokenOwner = 'not token owner';
string constant ErrWasMinted = 'address has already been minted';
string constant ErrWithdraw = 'withdraw failed';

interface IContractDeployer {
  function deploy(bytes memory bytecode, uint256 tokenID)
    external
    payable
    returns (address);

  function generateContractAddress(uint256 _nonce)
    external
    view
    returns (address);
}

contract DeployToken is ERC1155Supply, Ownable {
  using Strings for uint256;
  using ECDSA for bytes32;

  // Constants.
  address private signer;
  bool private _isMetadataLocked;

  address public contractDeployer;
  address public mintableContract;
  uint256 public ownMintPrice; 

  mapping(address => uint256) public addressToNonce;
  mapping(address => bool) public addressWasMinted;

  constructor(
    string memory _baseURI,
    address payable _owner,
    address _signer,
    address _contractDeployer
  ) ERC1155(_baseURI) {
    transferOwnership(_owner);
    signer = _signer;
    contractDeployer = _contractDeployer;
  }

  // Metadata
  function uri(uint256 tokenID)
    public
    view
    virtual
    override
    returns (string memory)
  {
    if (exists(tokenID)) {
      return super.uri(tokenID);
    }

    revert(ErrInvalidURI);
  }

  function setURI(string memory _newURI) external onlyOwner {
    require(!_isMetadataLocked, ErrLockedProperty);
    super._setURI(_newURI);
  }

  function lockMetadata() external onlyOwner {
    _isMetadataLocked = true;
  }
  // end Metadata

  // Minting methods.
  function mintAddresses(
    uint256 maxTimestamp,
    uint256 cost,
    uint256[] calldata nonces,
    address[] calldata addresses,
    bytes memory signature
  ) external payable {
    bytes32 hash = keccak256(
      abi.encodePacked(
        block.chainid,
        msg.sender,
        maxTimestamp,
        cost,
        nonces
      )
    );
    require(_isValidSigner(hash, signature), ErrNotSigner);

    require(block.timestamp <= maxTimestamp, ErrInvalidTime);
    require(msg.value >= cost, ErrNotEnoughValue);

    _mintAddresses(msg.sender, contractDeployer, nonces, addresses);
  }

  function mintAddressesFromContract(
    address _to,
    uint256[] calldata nonces,
    address[] calldata addresses
  ) external payable {
    require(msg.sender == mintableContract, ErrInvalidMintable);
    _mintAddresses(_to, contractDeployer, nonces, addresses);
  }

  function mintOwnAddresses(
    uint256[] calldata nonces,
    address[] calldata addresses
  ) external payable {
    require(msg.value >= ownMintPrice, ErrNotEnoughValue);
    _mintAddresses(msg.sender, msg.sender, nonces, addresses);
  }

  function _mintAddresses(
    address _to,
    address hasherAddress,
    uint256[] calldata nonces,
    address[] calldata addresses
  ) internal {
    require(
      nonces.length > 0 &&
        nonces.length == addresses.length,
      ErrInvalidLength
    );

    uint256[] memory amounts = new uint256[](nonces.length);
    uint256[] memory addressTokenIDs = new uint256[](nonces.length);
    for (uint256 i = 0; i < nonces.length; i++) {
      uint256 salt = generateSalt(hasherAddress, nonces[i]);
      address generatedAddress = IContractDeployer(contractDeployer)
        .generateContractAddress(salt);
      require(generatedAddress == addresses[i], ErrInvalidNonceAddress);
      require(!addressWasMinted[generatedAddress], ErrWasMinted);

      addressWasMinted[generatedAddress] = true;
      addressToNonce[generatedAddress] = salt;
      addressTokenIDs[i] = uint256(uint160(generatedAddress));

      amounts[i] = 1;
    }

    _mintBatch(_to, addressTokenIDs, amounts, '');
  }

  function setMintableContract(address _contractAddress) external onlyOwner {
    mintableContract = _contractAddress;
  }

  // end Minting methods.

  // Contract deployment methods.
  function deployContract(bytes memory bytecode, uint256 tokenID)
    external
    payable
  {
    require(balanceOf(msg.sender, tokenID) > 0, ErrNotTokenOwner);
    address deployableAddress = address(uint160(tokenID));
    uint256 nonce = addressToNonce[deployableAddress];

    IContractDeployer(contractDeployer).deploy{value: msg.value}(
      bytecode,
      nonce
    );
    _burn(msg.sender, tokenID, 1);
  }
  // end Contract deployment.
  
  // Util methods.
  function generateSalt(address hasherAddress, uint256 nonce) public pure returns (uint256) {
      return uint256(keccak256(abi.encodePacked(hasherAddress, nonce)));
  }
  // end Util methods.

  // Signer methods.
  function setSignerAddress(address _signer) external onlyOwner {
    signer = _signer;
  }

  function _isValidSigner(bytes32 hash, bytes memory signature)
    private
    view
    returns (bool)
  {
    require(signer != address(0), ErrInvalidSigner);

    bytes32 signedHash = hash.toEthSignedMessageHash();
    address recoveredAddress = signedHash.recover(signature);
    return recoveredAddress == signer;
  }

  // end Signer.

  // Admin methods.
  function setOwnMintPrice(uint256 _price) external onlyOwner {
    ownMintPrice = _price;
  }

  function withdraw() public onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}('');
    require(success, ErrWithdraw);
  }
  // end Admin.
}