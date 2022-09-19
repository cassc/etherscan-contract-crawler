//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

interface IMetadata {
  function setBaseUri(string memory _uri) external;

  function setTokenData(uint256 ensId, uint256 newId) external;
}

interface NameWrapper {
  function setSubnodeRecord(
    bytes32 parentNode,
    string memory label,
    address newOwner,
    address resolver,
    uint64 ttl,
    uint32 fuses,
    uint64 expiry
  ) external;

  function renew(
    uint256 tokenId,
    uint256 duration,
    uint64 expiry
  ) external;

  function ownerOf(uint256 id) external view returns (address);
}

interface ENSRegistry {
  function setResolver(bytes32 node, address resolver) external;

  function setAddr(
    bytes32 node,
    uint256 coinType,
    bytes memory a
  ) external;

  function setText(
    bytes32 node,
    string calldata key,
    string calldata value
  ) external;

  function resolver(bytes32 node) external view returns (address);

  function setApprovalForAll(address operator, bool approved) external;
}

// We do not approve of any minting directly from the contract.
// No warranties or promises are made by Company with respect to Nomads minted directly from the contract.
// By minting a Nomad from this contract you agree to all terms and conditions found on www.earth.domains.

contract NomadCustom is Initializable, OwnableUpgradeable, UUPSUpgradeable {
  event TokensMinted(address indexed to, uint256[] ensId);
  event TokenMinted(address indexed to, uint256 ensId);
  struct TokenData {
    uint256 created;
    uint256 expiration;
    uint256 registration;
    uint256 labelSize;
    string label;
  }
  using Strings for uint256;
  address public nameWrapper;
  address public metadataService;
  uint256 public price;
  uint256 public tokenCount;
  bool public salesOn;
  bytes32 public parentNode;
  mapping(uint256 => TokenData) public ensToTokenData;
  address public resolver;
  address _signer;
  string constant _START_SVG =
    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="100%" height="100%" viewBox="0 0 1000 1000"><defs><style>.cls-1 {clip-path: url(#clip-SVG_Sample_4);} .cls-2,.cls-4,.cls-5 {fill: #fff;} .cls-3 {fill: #2f7baf;} .cls-4 {display: inline-block;font-size: 56px;} .cls-7 {font-size: 36px;opacity: 60%;} .cls-4,.cls-5,.cls-7 {font-family: Arial-BoldMT, Arial;font-weight: 700;letter-spacing: -0.04em;} .cls-5 {font-size: 32px;opacity: 60%} .cls-6 {fill: url(#linear-gradient);}</style><linearGradient id="linear-gradient" x2="1" y2="1" gradientUnits="objectBoundingBox"><stop offset="0" stop-color="#c9cfff" /><stop offset="0.219" stop-color="#abc5ee" /><stop offset="1" stop-color="#3283a8" /></linearGradient><clipPath id="clip-SVG_Sample_4"><rect width="1000" height="1000" /></clipPath></defs><path id="text_path" pathLength="100" d="M 70,450 h 860 M 70,500 h 860 M 70,550 h 860 M 70,600 h 860 M 70,650 h 860 M 70,700 h 860 M 70,750 h 860 M 70,800 h 860 M 70,850 h 860 M 70,900 h 860" /><g id="SVG_Sample_4" data-name="SVG Sample 4" class="cls-1"><rect class="cls-6" width="1000" height="1000" /><g id="icon" transform="translate(91.001 68)"><circle id="Ellipse_28" data-name="Ellipse 28" class="cls-2" cx="35.5" cy="35.5" r="35.5" transform="translate(109.999 128)" /><g id="Group_8" data-name="Group 8" transform="translate(0 0)"><g id="Group_6" data-name="Group 6" transform="translate(0 0)"><path id="Subtraction_1" data-name="Subtraction 1" class="cls-3" d="M8.232,327.433a8.515,8.515,0,0,1-3.056-.511,4.323,4.323,0,0,1-1.167-.662,2.679,2.679,0,0,1-.755-.953,2.919,2.919,0,0,1-.035-2.148,9.025,9.025,0,0,1,1.842-2.983,15.721,15.721,0,0,0,1.674-3.287,33.3,33.3,0,0,0,1.3-4.358A79.631,79.631,0,0,0,9.664,301.25a242.139,242.139,0,0,0,.293-28.295c-.412-10.7-1.231-20.759-1.845-27.313-.7-7.514-1.432-13.55-1.81-15.979,2.048-.545,3.922-1.019,5.575-1.437l.014,0c3.345-.846,5.988-1.514,7.871-2.215a10.584,10.584,0,0,0,2.284-1.113,3.379,3.379,0,0,0,1.222-1.352c.476-1.039.248-2.384-.74-4.36-2.642-5.283-6.328-16.15-10.956-32.3C7.814,173.77,4.352,160.35,2.688,153.9l-.005-.02c-.5-1.921-.854-3.309-1.031-3.958a45.44,45.44,0,0,1-1.571-8.367,21.525,21.525,0,0,1,.32-6.11,19.472,19.472,0,0,1,1.737-4.855c.762-1.52,1.693-3.017,2.678-4.6,1.141-1.835,2.434-3.914,3.683-6.392a54.505,54.505,0,0,0,3.562-9.008c.563-1.88,1.067-3.893,1.5-5.984.467-2.264.866-4.7,1.185-7.236.341-2.716.6-5.639.776-8.688.184-3.236.276-6.715.272-10.339-.166-5.231-.452-10.392-.849-15.34-.37-4.611-.846-9.151-1.414-13.495A212.041,212.041,0,0,0,9.587,27.785,145.483,145.483,0,0,0,5.132,12.632a89.6,89.6,0,0,0-3.8-9.122c-.043-.088-.107-.2-.182-.328a6.014,6.014,0,0,1-.536-1.1A1.417,1.417,0,0,1,.645.9,1.555,1.555,0,0,1,1.53.254,6.317,6.317,0,0,1,3.522,0c.3,0,.628.011.973.033C8.776.321,13,.747,17.053,1.3c4.19.571,8.311,1.294,12.249,2.147,4.065.881,8.049,1.926,11.839,3.107C45.049,7.771,48.86,9.165,52.469,10.7a107.807,107.807,0,0,1,10.716,5.261c1.734.977,3.449,2.011,5.1,3.073,1.672,1.078,3.322,2.215,4.906,3.382,1.605,1.182,3.188,2.427,4.7,3.7,1.535,1.29,3.045,2.645,4.487,4.028,1.461,1.4,2.894,2.87,4.258,4.366,1.383,1.516,2.734,3.1,4.017,4.713,1.326,1.666,2.616,3.407,3.835,5.176,1.235,1.792,2.432,3.662,3.558,5.558,1.14,1.92,2.239,3.922,3.267,5.95,1.04,2.053,2.037,4.19,2.963,6.353.937,2.189,1.827,4.466,2.645,6.767.828,2.329,1.607,4.748,2.314,7.19.715,2.471,1.378,5.037,1.969,7.624.6,2.617,1.14,5.332,1.611,8.069.477,2.768.894,5.636,1.24,8.524.35,2.92.638,5.944.856,8.989.22,3.078.374,6.262.458,9.465.085,3.237.1,6.585.046,9.951-.055,3.4-.182,6.915-.379,10.448-.2,3.568-.473,7.253-.817,10.954-.347,3.739-.774,7.6-1.268,11.472-.5,3.912-1.083,7.95-1.733,12-.056.565-.116,1.451-.191,2.573a238.509,238.509,0,0,1-9.3,53.145c-.951,3.194-1.983,6.391-3.066,9.5-1.152,3.307-2.393,6.606-3.69,9.806-1.372,3.384-2.844,6.752-4.375,10.011-1.612,3.43-3.335,6.834-5.12,10.117-1.872,3.443-3.866,6.849-5.926,10.124-2.153,3.423-4.438,6.8-6.792,10.031-2.453,3.37-5.05,6.681-7.719,9.84-2.774,3.285-5.7,6.5-8.706,9.549a4.938,4.938,0,0,1-.787.645c-2.269,1.492-4.589,2.922-6.9,4.25-2.19,1.261-4.425,2.462-6.643,3.571a119.1,119.1,0,0,1-12.357,5.34,106.811,106.811,0,0,1-10.835,3.326c-3.024.751-6.043,1.35-8.971,1.778A11.171,11.171,0,0,1,8.232,327.433ZM45.206,159.708a2.413,2.413,0,0,0-1.132.468c-1.731,1.119-3.494,2.247-5.2,3.338l-.033.021-.055.035c-1.588,1.016-3.231,2.067-4.843,3.108-.084.054-.175.1-.272.152-.339.177-.689.359-.71.813a.794.794,0,0,0,.231.629,2.027,2.027,0,0,0,.533.342c.1.049.19.1.274.148l1.366.849c2.073,1.29,4.216,2.624,6.369,3.824,1.156.641,2.679,1.475,4.215,2.24,1.552.772,2.952,1.394,4.28,1.9a29.382,29.382,0,0,0,4.385,1.319,21.831,21.831,0,0,0,4.529.494h.006c.538,0,1.082-.023,1.616-.067.357.011.72.016,1.079.016a35.932,35.932,0,0,0,7.262-.743,30.061,30.061,0,0,0,5.431-1.605,31.587,31.587,0,0,0,4.993-2.554,36.805,36.805,0,0,0,4.6-3.431,46.152,46.152,0,0,0,4.238-4.235,1.649,1.649,0,0,0,.546-1.258,1.569,1.569,0,0,0-.822-1.022c-.989-.642-1.988-1.308-2.954-1.953l-.01-.006c-1.414-.943-2.876-1.919-4.336-2.837a5.347,5.347,0,0,0-2.066-1.031c-.591,0-.794.749-1.285,2.557l-.061.223a23.747,23.747,0,0,1-1.951,5.005,16.975,16.975,0,0,1-2.816,3.872,14.68,14.68,0,0,1-3.658,2.719,16.38,16.38,0,0,1-4.479,1.546,14.357,14.357,0,0,1-8.25-.827,15.955,15.955,0,0,1-4.687-2.987,17.3,17.3,0,0,1-1.923-2.065,17.733,17.733,0,0,1-1.581-2.372,17.546,17.546,0,0,1-1.943-5.445,2.039,2.039,0,0,0-.348-.92A.654.654,0,0,0,45.206,159.708Z" transform="translate(86.086 0)" /><ellipse id="Ellipse_26" data-name="Ellipse 26" class="cls-3" cx="39.989" cy="14.543" rx="39.989" ry="14.543" transform="translate(176.869 216.761) rotate(-78.94)" /><path id="Path_8679" data-name="Path 8679" class="cls-3" d="M1489.451,1628.33c11.781.288,20.264,5.24,28.733,10.211,1.878,1.1,3.7,2.3,5.49,3.538,1,.684,2.329,1.427,1.437,2.945-.975,1.654-2.253,1.095-3.58.263-3.555-2.231-7.185-4.345-10.74-6.579-2.558-1.607-3.507-1.261-4.1,2.013a14.837,14.837,0,0,1-14.1,12.094c-7.106.288-13.7-4.031-15.38-11.109-1.093-4.618-2.509-3.493-4.888-1.343-2.189,1.985-4.427,3.918-6.671,5.843a1.787,1.787,0,0,1-2.845-.178,1.656,1.656,0,0,1,.226-2.47C1471.028,1636.073,1479.015,1628.571,1489.451,1628.33Z" transform="translate(-1454.349 -1478.039)" /><path id="Path_8680" data-name="Path 8680" class="cls-3" d="M1457.364,1545.667a80.345,80.345,0,0,1,32.852,10.743c1.309.757,3.888,1.3,2.863,3.493-1.2,2.572-3.161.815-4.713-.047-14.433-8-29.66-11.836-46.194-8.845a53.176,53.176,0,0,0-22.791,10.121c-1.364,1.028-2.994,3.327-4.64,1.076s1.149-3.181,2.44-4.171A58.509,58.509,0,0,1,1457.364,1545.667Z" transform="translate(-1414.237 -1409.038)" /></g></g></g><text class="cls-4"><textPath startOffset="100%" text-anchor="end" dominant-baseline="bottom" xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="#text_path">';
  string constant _END_SVG =
    '<tspan class="cls-7">.earth.eth</tspan></textPath></text><text id="textBox-2" data-name="textBox" class="cls-5" transform="translate(728 81)"><tspan x="0" y="0">earth.domains</tspan></text></g></svg>';
  mapping(uint256 => uint256) public freeDomain;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address _nameWrapper,
    address _metadata,
    address _resolver,
    bytes32 node
  ) public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
    nameWrapper = _nameWrapper;
    metadataService = _metadata;
    resolver = _resolver;
    parentNode = node;
    _signer = 0x9C5F283070f16F2eF28C38BbcA544f656B92869d;
    price = 0.03 ether;
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}

  function _getMessageHash(
    string memory label,
    address to,
    uint256 token
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          "\x19Ethereum Signed Message:\n32",
          _getMessage(label, to, token)
        )
      );
  }

  function _getMessage(
    string memory label,
    address to,
    uint256 token
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(to, label, token));
  }

  function recover(
    string memory label,
    address to,
    uint256 token,
    bytes memory signature
  ) public view returns (bool) {
    bytes32 hash = _getMessageHash(label, to, token);
    return SignatureChecker.isValidSignatureNow(_signer, hash, signature);
  }

  /**
   * @notice Set the hash of the parent Node, only the owner can use the function
   * @param node namehash of the domain
   */
  function setParentNode(bytes32 node) public onlyOwner {
    parentNode = node;
  }

  function setSales(bool _sales) public onlyOwner {
    salesOn = _sales;
  }

  /**
   * @notice Set the address of the nameWrapper contract, only the owner can use the function
   * @param _nameWrapper address of the nameWrapper contract
   */
  function setNameWrapper(address _nameWrapper) public onlyOwner {
    nameWrapper = _nameWrapper;
  }

  /**
   * @notice Set the address for the metadata service;
   * @param _metadata address of the metadata contract
   */
  function setMetadataService(address _metadata) public onlyOwner {
    metadataService = _metadata;
  }

  /**
   * @notice Set the minting price, only the owner can use the function
   * @param _price minting price
   */
  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  /**
   * @notice compute an hash from a parent node and a subdomain labelhash
   * @dev taken From ens nameWrapper contract
   * @param node hash of a parent node
   * @param label labelhash of the subdomain
   */
  function _makeNode(bytes32 node, bytes32 label)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(node, label));
  }

  function areTokensAvailable(uint256[] calldata tokens)
    public
    view
    returns (bool[] memory)
  {
    bool[] memory ret = new bool[](tokens.length);
    for (uint256 index = 0; index < tokens.length; index++) {
      string memory label = tokens[index].toString();
      if (tokens[index] < 10) label = string(abi.encodePacked("00", label));
      else if (tokens[index] < 100)
        label = string(abi.encodePacked("0", label));
      bytes32 labelhash = keccak256(bytes(label));
      bytes32 ensId = _makeNode(parentNode, labelhash);
      ret[index] =
        NameWrapper(nameWrapper).ownerOf(uint256(ensId)) == address(0);
    }
    return ret;
  }

  function computePrice(bytes memory data)
    public
    view
    returns (uint256 priceOverride)
  {
    (, uint256 tokenId, ) = abi.decode(data, (string, uint256, bytes));
    uint8 freeCount = tokenId <= 535 ? 2 : 1;
    if (freeDomain[tokenId] < freeCount && tokenId != 0) priceOverride = 0;
    else priceOverride = price;
  }

  function mint(address to, bytes memory data) public payable {
    (string memory label, uint256 tokenId, bytes memory signature) = abi.decode(
      data,
      (string, uint256, bytes)
    );
    require(recover(label, to, tokenId, signature), "Wrong signature");
    uint8 freeCount = tokenId <= 535 ? 2 : 1;
    uint256 priceOverride;
    if (freeDomain[tokenId] < freeCount && tokenId != 0) priceOverride = 0;
    else priceOverride = price;
    freeDomain[tokenId]++;
    require(msg.value == priceOverride, "Wrong Value");
    bytes32 labelhash = keccak256(bytes(label));
    bytes32 ensId = _makeNode(parentNode, labelhash);
    if (NameWrapper(nameWrapper).ownerOf(uint256(ensId)) != address(0)) {
      revert("Token not available");
    }
    NameWrapper(nameWrapper).setSubnodeRecord(
      parentNode,
      label,
      to,
      resolver,
      type(uint64).max,
      0,
      31536000 //1 year in sec
    );
    ensToTokenData[uint256(ensId)].created = block.timestamp;
    ensToTokenData[uint256(ensId)].expiration = block.timestamp + 31536000;
    ensToTokenData[uint256(ensId)].registration = block.timestamp;
    ensToTokenData[uint256(ensId)].labelSize = bytes(label).length;
    ensToTokenData[uint256(ensId)].label = label;
    _setTokenData(uint256(ensId), tokenCount);
    emit TokenMinted(to, tokenCount);
    tokenCount++;
  }

  function mintTeam(address to, string memory label) public onlyOwner {
    bytes32 labelhash = keccak256(bytes(label));
    bytes32 ensId = _makeNode(parentNode, labelhash);
    if (NameWrapper(nameWrapper).ownerOf(uint256(ensId)) != address(0)) {
      revert("Token not available");
    }
    NameWrapper(nameWrapper).setSubnodeRecord(
      parentNode,
      label,
      to,
      resolver,
      type(uint64).max,
      0,
      31536000 //1 year in sec
    );
    ensToTokenData[uint256(ensId)].created = block.timestamp;
    ensToTokenData[uint256(ensId)].expiration = block.timestamp + 31536000;
    ensToTokenData[uint256(ensId)].registration = block.timestamp;
    ensToTokenData[uint256(ensId)].labelSize = bytes(label).length;
    ensToTokenData[uint256(ensId)].label = label;
    _setTokenData(uint256(ensId), tokenCount);
    emit TokenMinted(to, tokenCount);
    tokenCount++;
  }

  function withdraw() public {
    uint256 balance = address(this).balance;
    (bool success, ) = payable(0x83C6ec2d12e80443e0C163954713A0EF614f7a83).call{
      value: balance
    }("");
    require(success);
  }

  function uri(uint256 ensID) public view returns (string memory) {
    string memory svg = Base64.encode(
      abi.encodePacked(_START_SVG, ensToTokenData[ensID].label, _END_SVG)
    );
    string memory json = Base64.encode(
      abi.encodePacked(
        '{"description":"',
        ensToTokenData[ensID].label,
        ' an earth.domains name","external_url":"earth.domains","name":"',
        ensToTokenData[ensID].label,
        '","animation_url":"data:image/svg+xml;base64,',
        svg,
        '","image":"data:image/svg+xml;base64,',
        svg,
        '","attributes":[{"display_type":"date","trait_type": "Expiration Date","value":"',
        ensToTokenData[ensID].expiration.toString(),
        '"},{"display_type":"date","trait_type": "Created Date","value":"',
        ensToTokenData[ensID].created.toString(),
        '"},{"display_type":"number","trait_type": "Length","value":"',
        ensToTokenData[ensID].labelSize.toString(),
        '"}]}'
      )
    );
    return string(abi.encodePacked("data:application/json;base64,", json));
  }

  function _computeLeaf(address user) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(user));
  }

  function setResolverAddr(address _resolver) public onlyOwner {
    resolver = _resolver;
  }

  /**
   * @notice setBaseUri that will be used by the token of that contract
   * @param _uri URI used.
   */

  function setBaseUri(string memory _uri) public onlyOwner {
    IMetadata(metadataService).setBaseUri(_uri);
  }

  function _setTokenData(uint256 ensId, uint256 newId) internal {
    IMetadata(metadataService).setTokenData(ensId, newId);
  }
}