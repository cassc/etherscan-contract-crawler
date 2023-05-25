// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity ^0.8.7;


//   /$$$$$$
//  /$$__  $$
// | $$  \__/  /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$  /$$$$$$$$
// | $$       /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$|____ /$$/
// | $$      | $$  \__/| $$$$$$$$| $$$$$$$$| $$  \ $$   /$$$$/
// | $$    $$| $$      | $$_____/| $$_____/| $$  | $$  /$$__/
// |  $$$$$$/| $$      |  $$$$$$$|  $$$$$$$| $$$$$$$/ /$$$$$$$$
//  \______/ |__/       \_______/ \_______/| $$____/ |________/
//                                         | $$
//                                         | $$
//                                         |__/
//
//  /$$$$$$                                         /$$
// |_  $$_/                                        |__/
//   | $$   /$$$$$$$  /$$    /$$ /$$$$$$   /$$$$$$$ /$$  /$$$$$$  /$$$$$$$
//   | $$  | $$__  $$|  $$  /$$/|____  $$ /$$_____/| $$ /$$__  $$| $$__  $$
//   | $$  | $$  \ $$ \  $$/$$/  /$$$$$$$|  $$$$$$ | $$| $$  \ $$| $$  \ $$
//   | $$  | $$  | $$  \  $$$/  /$$__  $$ \____  $$| $$| $$  | $$| $$  | $$
//  /$$$$$$| $$  | $$   \  $/  |  $$$$$$$ /$$$$$$$/| $$|  $$$$$$/| $$  | $$
// |______/|__/  |__/    \_/    \_______/|_______/ |__/ \______/ |__/  |__/
//
//
//
//   /$$$$$$                                                /$$
//  /$$__  $$                                              | $$
// | $$  \__/  /$$$$$$   /$$$$$$  /$$   /$$ /$$$$$$$   /$$$$$$$  /$$$$$$$
// | $$ /$$$$ /$$__  $$ /$$__  $$| $$  | $$| $$__  $$ /$$__  $$ /$$_____/
// | $$|_  $$| $$  \__/| $$  \ $$| $$  | $$| $$  \ $$| $$  | $$|  $$$$$$
// | $$  \ $$| $$      | $$  | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
// |  $$$$$$/| $$      |  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/
//  \______/ |__/       \______/  \______/ |__/  |__/ \_______/|_______/


contract CreepzInvasionGrounds is Ownable, ReentrancyGuard {
    IERC721 public CBCNft;
    IERC721 public ARMSNft;
    IERC721 public BLACKBOXNft;

    uint256 public constant SECONDS_IN_DAY = 24 * 60 * 60;
    uint256 public constant ACCELERATED_YIELD_DAYS = 2;
    uint256 public constant ACCELERATED_YIELD_MULTIPLIER = 2;
    uint256 public acceleratedYield;

    address public signerAddress;
    address[] public authorisedLog;

    bool public stakingLaunched;
    bool public depositPaused;

    struct Staker {
      uint256 currentYield;
      uint256 accumulatedAmount;
      uint256 lastCheckpoint;
      uint256[] stakedCBC;
      uint256[] stakedARMS;
      uint256[] stakedBLACKBOX;
    }

    enum ContractTypes {
      CBC,
      ARMS,
      BLACKBOX
    }

    mapping(address => uint256) public _baseRates;
    mapping(address => Staker) private _stakers;
    mapping(address => mapping(uint256 => address)) private _ownerOfToken;
    mapping(address => ContractTypes) private _contractTypes;
    mapping(address => mapping(uint256 => uint256)) private _tokensMultiplier;
    mapping (address => bool) private _authorised;

    event Deposit(address indexed staker,address contractAddress,uint256 tokensAmount);
    event Withdraw(address indexed staker,address contractAddress,uint256 tokensAmount);
    event AutoDeposit(address indexed contractAddress,uint256 tokenId,address indexed owner);
    event WithdrawStuckERC721(address indexed receiver, address indexed tokenAddress, uint256 indexed tokenId);

    constructor(
      address _cbc,
      address _signer
    ) {
        CBCNft = IERC721(_cbc);
        _contractTypes[_cbc] = ContractTypes.CBC;
        _baseRates[_cbc] = 1500 ether;

        signerAddress = _signer;
    }

    modifier authorised() {
      require(_authorised[_msgSender()], "The token contract is not authorised");
        _;
    }

    function deposit(
      address contractAddress,
      uint256[] memory tokenIds,
      uint256[] memory tokenTraits,
      bytes calldata signature
    ) public nonReentrant {
      require(!depositPaused, "Deposit paused");
      require(stakingLaunched, "Staking is not launched yet");
      require(
        contractAddress != address(0) &&
        contractAddress == address(CBCNft)
        || contractAddress == address(BLACKBOXNft)
        || contractAddress == address(ARMSNft),
        "Unknown contract"
      );
      ContractTypes contractType = _contractTypes[contractAddress];

      if (tokenTraits.length > 0) {
        require(_validateSignature(
          signature,
          contractAddress,
          tokenIds,
          tokenTraits
        ), "Invalid data provided");
        _setTokensValues(contractAddress, tokenIds, tokenTraits);
      }

      Staker storage user = _stakers[_msgSender()];
      uint256 newYield = user.currentYield;

      for (uint256 i; i < tokenIds.length; i++) {
        require(IERC721(contractAddress).ownerOf(tokenIds[i]) == _msgSender(), "Not the owner");
        IERC721(contractAddress).safeTransferFrom(_msgSender(), address(this), tokenIds[i]);

        _ownerOfToken[contractAddress][tokenIds[i]] = _msgSender();

        if (user.currentYield != 0 || contractType != ContractTypes.ARMS) {
          newYield += getTokenYield(contractAddress, tokenIds[i]);
        }

        if (contractType == ContractTypes.CBC) { user.stakedCBC.push(tokenIds[i]); }
        if (contractType == ContractTypes.ARMS) { user.stakedARMS.push(tokenIds[i]); }
        if (contractType == ContractTypes.BLACKBOX) { user.stakedBLACKBOX.push(tokenIds[i]); }
      }

      if (user.currentYield == 0 && newYield != 0 && user.stakedARMS.length > 0) {
        for (uint256 i; i < user.stakedARMS.length; i++) {
          uint256 tokenYield = getTokenYield(address(ARMSNft), user.stakedARMS[i]);
          newYield += tokenYield;
        }
      }

      accumulate(_msgSender());
      user.currentYield = newYield;

      emit Deposit(_msgSender(), contractAddress, tokenIds.length);
    }

    function withdraw(
      address contractAddress,
      uint256[] memory tokenIds
    ) public nonReentrant {
      require(
        contractAddress != address(0) &&
        contractAddress == address(CBCNft)
        || contractAddress == address(BLACKBOXNft)
        || contractAddress == address(ARMSNft),
        "Unknown contract"
      );
      ContractTypes contractType = _contractTypes[contractAddress];
      Staker storage user = _stakers[_msgSender()];
      uint256 newYield = user.currentYield;

      for (uint256 i; i < tokenIds.length; i++) {
        require(IERC721(contractAddress).ownerOf(tokenIds[i]) == address(this), "Not the owner");

        _ownerOfToken[contractAddress][tokenIds[i]] = address(0);

        if (user.currentYield != 0) {
          uint256 tokenYield = getTokenYield(contractAddress, tokenIds[i]);
          newYield -= tokenYield;
        }

        if (contractType == ContractTypes.CBC) {
          user.stakedCBC = _moveTokenInTheList(user.stakedCBC, tokenIds[i]);
          user.stakedCBC.pop();
        }
        if (contractType == ContractTypes.ARMS) {
          user.stakedARMS = _moveTokenInTheList(user.stakedARMS, tokenIds[i]);
          user.stakedARMS.pop();
        }
        if (contractType == ContractTypes.BLACKBOX) {
          user.stakedBLACKBOX = _moveTokenInTheList(user.stakedBLACKBOX, tokenIds[i]);
          user.stakedBLACKBOX.pop();
        }

        IERC721(contractAddress).safeTransferFrom(address(this), _msgSender(), tokenIds[i]);
      }

      if (user.stakedCBC.length == 0 && user.stakedBLACKBOX.length == 0) {
        newYield = 0;
      }

      accumulate(_msgSender());
      user.currentYield = newYield;

      emit Withdraw(_msgSender(), contractAddress, tokenIds.length);
    }

    function registerDeposit(address owner, address contractAddress, uint256 tokenId) public authorised {
      require(
        contractAddress != address(0) &&
        (contractAddress == address(BLACKBOXNft)
        || contractAddress == address(ARMSNft)),
        "Unknown contract"
      );
      require(IERC721(contractAddress).ownerOf(tokenId) == address(this), "!Owner");
      require(ownerOf(contractAddress, tokenId) == address(0), "Already deposited");

      _ownerOfToken[contractAddress][tokenId] = owner;

      Staker storage user = _stakers[owner];
      ContractTypes contractType = _contractTypes[contractAddress];
      uint256 newYield = user.currentYield;

      if (user.currentYield != 0 || contractType != ContractTypes.ARMS) {
        newYield += getTokenYield(contractAddress, tokenId);
      }

      if (contractType == ContractTypes.ARMS) { user.stakedARMS.push(tokenId); }
      if (contractType == ContractTypes.BLACKBOX) { user.stakedBLACKBOX.push(tokenId); }

      if (user.currentYield == 0 && newYield != 0 && user.stakedARMS.length > 0) {
        for (uint256 i; i < user.stakedARMS.length; i++) {
          uint256 tokenYield = getTokenYield(address(ARMSNft), user.stakedARMS[i]);
          newYield += tokenYield;
        }
      }

      accumulate(owner);
      user.currentYield = newYield;

      emit AutoDeposit(contractAddress, tokenId, _msgSender());
    }

    function getAccumulatedAmount(address staker) external view returns (uint256) {
      return _stakers[staker].accumulatedAmount + getCurrentReward(staker);
    }

    function getTokenYield(address contractAddress, uint256 tokenId) public view returns (uint256) {
      uint256 tokenYield = _tokensMultiplier[contractAddress][tokenId];
      if (tokenYield == 0) { tokenYield = _baseRates[contractAddress]; }

      return tokenYield;
    }

    function getStakerYield(address staker) public view returns (uint256) {
      return _stakers[staker].currentYield;
    }

    function getStakerTokens(address staker) public view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
      return (_stakers[staker].stakedCBC, _stakers[staker].stakedARMS, _stakers[staker].stakedBLACKBOX);
    }

    function isMultiplierSet(address contractAddress, uint256 tokenId) public view returns (bool) {
      return _tokensMultiplier[contractAddress][tokenId] > 0;
    }

    function _moveTokenInTheList(uint256[] memory list, uint256 tokenId) internal pure returns (uint256[] memory) {
      uint256 tokenIndex = 0;
      uint256 lastTokenIndex = list.length - 1;
      uint256 length = list.length;

      for(uint256 i = 0; i < length; i++) {
        if (list[i] == tokenId) {
          tokenIndex = i + 1;
          break;
        }
      }
      require(tokenIndex != 0, "msg.sender is not the owner");

      tokenIndex -= 1;

      if (tokenIndex != lastTokenIndex) {
        list[tokenIndex] = list[lastTokenIndex];
        list[lastTokenIndex] = tokenId;
      }

      return list;
    }

    function _validateSignature(
      bytes calldata signature,
      address contractAddress,
      uint256[] memory tokenIds,
      uint256[] memory tokenTraits
      ) internal view returns (bool) {
      bytes32 dataHash = keccak256(abi.encodePacked(contractAddress, tokenIds, tokenTraits));
      bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

      address receivedAddress = ECDSA.recover(message, signature);
      return (receivedAddress != address(0) && receivedAddress == signerAddress);
    }

    function _setTokensValues(
      address contractAddress,
      uint256[] memory tokenIds,
      uint256[] memory tokenTraits
    ) internal {
      require(tokenIds.length == tokenTraits.length, "Wrong arrays provided");
      for (uint256 i; i < tokenIds.length; i++) {
        if (tokenTraits[i] != 0 && tokenTraits[i] <= 3000 ether) {
          _tokensMultiplier[contractAddress][tokenIds[i]] = tokenTraits[i];
        }
      }
    }

    function getCurrentReward(address staker) public view returns (uint256) {
      Staker memory user = _stakers[staker];
      if (user.lastCheckpoint == 0) { return 0; }
      if (user.lastCheckpoint < acceleratedYield && block.timestamp < acceleratedYield) {
        return (block.timestamp - user.lastCheckpoint) * user.currentYield / SECONDS_IN_DAY * ACCELERATED_YIELD_MULTIPLIER;
      }
      if (user.lastCheckpoint < acceleratedYield && block.timestamp > acceleratedYield) {
        uint256 currentReward;
        currentReward += (acceleratedYield - user.lastCheckpoint) * user.currentYield / SECONDS_IN_DAY * ACCELERATED_YIELD_MULTIPLIER;
        currentReward += (block.timestamp - acceleratedYield) * user.currentYield / SECONDS_IN_DAY;
        return currentReward;
      }
      return (block.timestamp - user.lastCheckpoint) * user.currentYield / SECONDS_IN_DAY;
    }

    function accumulate(address staker) internal {
      _stakers[staker].accumulatedAmount += getCurrentReward(staker);
      _stakers[staker].lastCheckpoint = block.timestamp;
    }

    /**
    * @dev Returns token owner address (returns address(0) if token is not inside the gateway)
    */
    function ownerOf(address contractAddress, uint256 tokenId) public view returns (address) {
      return _ownerOfToken[contractAddress][tokenId];
    }

    function setArmsContract(address _arms, uint256 _baseReward) public onlyOwner {
      ARMSNft = IERC721(_arms);
      _contractTypes[_arms] = ContractTypes.ARMS;
      _baseRates[_arms] = _baseReward;
    }

    function setBlackboxContract(address _blackBox, uint256 _baseReward) public onlyOwner {
      BLACKBOXNft = IERC721(_blackBox);
      _contractTypes[_blackBox] = ContractTypes.BLACKBOX;
      _baseRates[_blackBox] = _baseReward;
    }

    /**
    * @dev Admin function to authorise the contract address
    */
    function authorise(address toAuth) public onlyOwner {
      _authorised[toAuth] = true;
      authorisedLog.push(toAuth);
    }

    /**
    * @dev Function allows admin add unauthorised address.
    */
    function unauthorise(address addressToUnAuth) public onlyOwner {
      _authorised[addressToUnAuth] = false;
    }

    /**
    * @dev Function allows admin withdraw ERC721 in case of emergency.
    */
    function emergencyWithdraw(address tokenAddress, uint256[] memory tokenIds) public onlyOwner {
      require(tokenIds.length <= 50, "50 is max per tx");
      pauseDeposit(true);
      for (uint256 i; i < tokenIds.length; i++) {
        address receiver = _ownerOfToken[tokenAddress][tokenIds[i]];
        if (receiver != address(0) && IERC721(tokenAddress).ownerOf(tokenIds[i]) == address(this)) {
          IERC721(tokenAddress).transferFrom(address(this), receiver, tokenIds[i]);
          emit WithdrawStuckERC721(receiver, tokenAddress, tokenIds[i]);
        }
      }
    }


    /**
    * @dev Function allows to pause deposits if needed. Withdraw remains active.
    */
    function pauseDeposit(bool _pause) public onlyOwner {
      depositPaused = _pause;
    }

    /**
    * @dev Function allows to pause deposits if needed. Withdraw remains active.
    */
    function updateSignerAddress(address _signer) public onlyOwner {
      signerAddress = _signer;
    }

    function launchStaking() public onlyOwner {
      require(!stakingLaunched, "Staking has been launched already");
      stakingLaunched = true;
      acceleratedYield = block.timestamp + (SECONDS_IN_DAY * ACCELERATED_YIELD_DAYS);
    }

    function updateBaseYield(address _contract, uint256 _yield) public onlyOwner {
      _baseRates[_contract] = _yield;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns(bytes4){
      return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}