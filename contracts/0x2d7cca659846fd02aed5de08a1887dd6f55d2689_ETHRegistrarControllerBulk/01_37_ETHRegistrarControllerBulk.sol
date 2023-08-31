pragma solidity >=0.8.4;

import './BaseRegistrarImplementation.sol';
import './StringUtils.sol';
import '../resolvers/Resolver.sol';
import '../registry/ReverseRegistrar.sol';
import './IETHRegistrarController.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '../wrapper/INameWrapper.sol';
import './IERC20.sol';

/**
 * @dev A registrar controller for registering Bulk names
 */
contract ETHRegistrarControllerBulk is Ownable {
  using StringUtils for *;
  using Address for address;

  uint256 public constant MIN_REGISTRATION_DURATION = 28 days;

  uint8 public MIN_DOMAIN_LENGTH = 3;

  BaseRegistrarImplementation immutable base;
  IPriceOracle public immutable prices;
  ReverseRegistrar public immutable reverseRegistrar;
  INameWrapper public immutable nameWrapper;

  IETHRegistrarController public registrarETH;

  IERC20 public tomi;
  address public auction;

  event NameRegistered(
    IETHRegistrarController.domain name,
    bytes32 indexed label,
    address indexed owner,
    uint256 baseCost,
    uint256 premium,
    uint256 expires
  );
  event MinLengthChanged(
    uint8 oldLength,
    uint8 newLength
  );

  constructor(
    BaseRegistrarImplementation _base,
    IPriceOracle _prices,
    ReverseRegistrar _reverseRegistrar,
    INameWrapper _nameWrapper,
    IERC20 _tomi,
    IETHRegistrarController _registrar,
    address auction_
  ) {
    base = _base;
    prices = _prices;
    reverseRegistrar = _reverseRegistrar;
    nameWrapper = _nameWrapper;
    tomi = _tomi;
    registrarETH = _registrar;
    auction = auction_;
  }

  /**
   * @notice Set the auction service. Only the owner can do this
   */

  function setAuction(address _auction) external onlyOwner {
    auction = _auction;
  }

  /**
   * @notice Set the MIN DOMAIN LENGTH. Only the owner can do this
   */

  function setMinDomainLength(uint8 _length) external onlyOwner {
    emit MinLengthChanged(MIN_DOMAIN_LENGTH , _length);
    MIN_DOMAIN_LENGTH = _length;
  }

  function rentPrice(
    string memory name,
    uint256 duration,
    bytes32 tld_
  ) public view returns (IPriceOracle.Price memory price) {
    bytes32 label = keccak256(bytes(name));
    price = prices.price(
      name,
      base.nameExpires(uint256(label)),
      duration,
      tld_
    );
  }

  function valid(
    string memory name,
    string memory tld
  ) public view returns (bool) {
    return
      registrarETH.NODES(tld) != bytes32(0) &&
      name.strlen() >= MIN_DOMAIN_LENGTH;
  }

  function available(
    string memory name,
    string memory tld
  ) public view returns (bool) {
    bytes32 label = keccak256(bytes(name));
    bytes32 node = _makeNode(registrarETH.NODES(tld), label);
    return valid(name, tld) && base.available(uint256(node));
  }

  function register(
    IETHRegistrarController.domain[] calldata domain,
    uint256 duration,
    address resolver,
    bytes[][] calldata datas,
    bool reverseRecord
  ) public payable {
    uint256 total = 0;
    for (uint i = 0; i < domain.length; i++) {
      IETHRegistrarController.domain memory name = domain[i];
      bytes[] calldata data = datas[i];
      if (available(name.name, name.tld)) {
        IPriceOracle.Price memory price = rentPrice(
          name.name,
          duration,
          registrarETH.NODES(name.tld)
        );

        if (registrarETH.NODES(name.tld) != bytes32(0)) {
          total += (price.base + price.premium);

          uint256 expires = nameWrapper.registerAndWrapETH2LD(
            name,
            msg.sender,
            duration,
            resolver,
            price.base + price.premium
          );

          bytes32 nodehash = keccak256(
            abi.encodePacked(
              registrarETH.NODES(name.tld),
              keccak256(bytes(name.name))
            )
          );

          _setRecords(resolver, nodehash, data);

          if (reverseRecord) {
            _setReverseRecord(
              string.concat(name.name, name.tld),
              resolver,
              msg.sender
            );
          }

          emit NameRegistered(
            name,
            keccak256(bytes(name.name)),
            msg.sender,
            price.base,
            price.premium,
            expires
          );
        }
      }
    }

    tomi.transferFrom(msg.sender, auction, total);
  }

  function withdraw() public {
    payable(owner()).transfer(address(this).balance);
  }

  function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
    return
      interfaceID == type(IERC165).interfaceId ||
      interfaceID == type(IETHRegistrarController).interfaceId;
  }

  function _setRecords(
    address resolver,
    bytes32 nodehash,
    bytes[] calldata data
  ) internal {
    for (uint256 i = 0; i < data.length; i++) {
      // check first few bytes are namehash
      bytes32 txNamehash = bytes32(data[i][4:36]);
      require(
        txNamehash == nodehash,
        'ETHRegistrarController: Namehash on record do not match the name being registered'
      );
      resolver.functionCall(
        data[i],
        'ETHRegistrarController: Failed to set Record'
      );
    }
  }

  function _setReverseRecord(
    string memory name,
    address resolver,
    address owner
  ) internal {
    reverseRegistrar.setNameForAddr(msg.sender, owner, resolver, name);
  }

  function _makeNode(
    bytes32 node,
    bytes32 labelhash
  ) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(node, labelhash));
  }

  function computeNamehash(
    string calldata _name
  ) public pure returns (bytes32 namehash_) {
    namehash_ = 0x0000000000000000000000000000000000000000000000000000000000000000;
    namehash_ = keccak256(
      abi.encodePacked(namehash_, keccak256(abi.encodePacked(_name)))
    );
  }
}