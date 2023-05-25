// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.7;


//  /$$                                 /$$               /$$$         /$$$$$$              
// | $$                                | $$              /$$ $$       /$$__  $$             
// | $$        /$$$$$$   /$$$$$$   /$$$$$$$  /$$$$$$$   |  $$$       | $$  \__/  /$$$$$$    
// | $$       /$$__  $$ /$$__  $$ /$$__  $$ /$$_____/    /$$ $$/$$   | $$       /$$__  $$   
// | $$      | $$  \ $$| $$  \__/| $$  | $$|  $$$$$$    | $$  $$_/   | $$      | $$  \ $$   
// | $$      | $$  | $$| $$      | $$  | $$ \____  $$   | $$\  $$    | $$    $$| $$  | $$   
// | $$$$$$$$|  $$$$$$/| $$      |  $$$$$$$ /$$$$$$$/   |  $$$$/$$   |  $$$$$$/|  $$$$$$//$$
// |________/ \______/ |__/       \_______/|_______/     \____/\_/    \______/  \______/|__/                                                                           


interface ILoomi  {
  function depositLoomiFor(address user, uint256 amount) external;
  function activeTaxCollectedAmount() external view returns (uint256);
}

interface IStaking {
  function ownerOf(address contractAddress, uint256 tokenId) external view returns (address);
}

contract LordsAndCo is Ownable, ReentrancyGuard {
    
    // Creepz Contracts
    IERC721 public loomiVault;
    IERC721 public creepz;
    ILoomi public loomi;
    IStaking public staking;

    // Variables for daily yield
    uint256 public constant SECONDS_IN_DAY = 24 * 60 * 60;
    uint256 public constant DIVIDER = 10000;
    uint256 public baseYield;

    // Config bools
    bool public isPaused;
    bool public creepzRestriction;

    struct Staker {
      uint256 accumulatedAmount;
      uint256 lastCheckpoint;
      uint256 loomiPotSnapshot;
      uint256[] stakedVault;
    }

    mapping(address => Staker) private _stakers;
    mapping(uint256 => address) private _ownerOfToken;

    event Deposit(address indexed staker,uint256 tokensAmount);
    event Withdraw(address indexed staker,uint256 tokensAmount);
    event Claim(address indexed staker,uint256 tokensAmount);
    event WithdrawStuckERC721(address indexed receiver, address indexed tokenAddress, uint256 indexed tokenId);

    constructor(
      address _loomiVault,
      address _loomi,
      address _creepz,
      address _staking
    ) {
        loomiVault = IERC721(_loomiVault);
        loomi = ILoomi(_loomi);
        creepz = IERC721(_creepz);
        staking = IStaking(_staking);

        isPaused = true;
        creepzRestriction = true;
        baseYield = 500 ether;
    }

    modifier whenNotPaused() {
      require(!isPaused, "Contract paused");
        _;
    }

    /**
    * @dev Function for loomiVault deposit
    */
    function deposit(uint256[] memory tokenIds) public nonReentrant whenNotPaused {
      require(tokenIds.length > 0, "Empty array");
      Staker storage user = _stakers[_msgSender()];

      if (user.stakedVault.length == 0) {
        uint256 currentLoomiPot = _getLoomiPot();
        user.loomiPotSnapshot = currentLoomiPot;
      } 
      accumulate(_msgSender());

      for (uint256 i; i < tokenIds.length; i++) {
        require(loomiVault.ownerOf(tokenIds[i]) == _msgSender(), "Not the owner");
        loomiVault.safeTransferFrom(_msgSender(), address(this), tokenIds[i]);

        _ownerOfToken[tokenIds[i]] = _msgSender();

        user.stakedVault.push(tokenIds[i]);
      }

      emit Deposit(_msgSender(), tokenIds.length);
    }

    /**
    * @dev Function for loomiVault withdraw
    */
    function withdraw(uint256[] memory tokenIds) public nonReentrant whenNotPaused {
      require(tokenIds.length > 0, "Empty array");

      Staker storage user = _stakers[_msgSender()];
      accumulate(_msgSender());

      for (uint256 i; i < tokenIds.length; i++) {
        require(loomiVault.ownerOf(tokenIds[i]) == address(this), "Not the owner");

        _ownerOfToken[tokenIds[i]] = address(0);
        user.stakedVault = _moveTokenInTheList(user.stakedVault, tokenIds[i]);
        user.stakedVault.pop();

        loomiVault.safeTransferFrom(address(this), _msgSender(), tokenIds[i]);
      }

      emit Withdraw(_msgSender(), tokenIds.length);
    }

    /**
    * @dev Function for loomi reward claim
    * @notice caller must own a Genesis Creepz
    */
    function claim(uint256 tokenId) public nonReentrant whenNotPaused {
      Staker storage user = _stakers[_msgSender()];
      accumulate(_msgSender());

      require(user.accumulatedAmount > 0, "Insufficient funds");
      require(_validateCreepzOwner(tokenId, _msgSender()), "!Creepz owner");

      uint256 currentLoomiPot = _getLoomiPot();
      uint256 prevLoomiPot = user.loomiPotSnapshot;
      uint256 change = currentLoomiPot * DIVIDER / prevLoomiPot;
      uint256 finalAmount = user.accumulatedAmount * change / DIVIDER;

      user.loomiPotSnapshot = currentLoomiPot;
      user.accumulatedAmount = 0;
      loomi.depositLoomiFor(_msgSender(), finalAmount);

      emit Claim(_msgSender(), finalAmount);
    }

    /**
    * @dev Function for Genesis Creepz ownership validation
    */
    function _validateCreepzOwner(uint256 tokenId, address user) internal view returns (bool) {
      if (!creepzRestriction) return true;
      if (staking.ownerOf(address(creepz), tokenId) == user) {
        return true;
      }
      return creepz.ownerOf(tokenId) == user;
    }

    /**
    * @dev Returns accumulated $loomi amount for user based on baseRate
    */
    function getAccumulatedAmount(address staker) external view returns (uint256) {
      return _stakers[staker].accumulatedAmount + getCurrentReward(staker);
    }

    /**
    * @dev Returnes pot change from the last user claim
    */
    function getPriceChange(address user) public view returns (uint256) {
      if (_stakers[user].loomiPotSnapshot == 0) return 0;
      uint256 currentLoomiPot = _getLoomiPot();
      uint256 change = currentLoomiPot * DIVIDER / _stakers[user].loomiPotSnapshot;

      return change;
    }

    /**
    * @dev Returnes $loomi yield rate for user based on baseRate
    */
    function getStakerYield(address staker) public view returns (uint256) {
      return _stakers[staker].stakedVault.length * baseYield;
    }

    /**
    * @dev Returns array of IDs staked by address
    */
    function getStakerTokens(address staker) public view returns (uint256[] memory) {
      return _stakers[staker].stakedVault;
    }

    /**
    * @dev Returns current $loomi pot
    */
    function getLoomiPot() public view returns (uint256) {
      return _getLoomiPot();
    }

    /**
    * @dev Helper function for arrays
    */
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

    /**
    * @dev Returns current $loomi pot
    */
    function _getLoomiPot() internal view returns (uint256) {
      uint256 pot = loomi.activeTaxCollectedAmount();
      return pot;
    }

    /**
    * @dev Returns accumulated amount from last snapshot based on baseRate
    */
    function getCurrentReward(address staker) public view returns (uint256) {
      Staker memory user = _stakers[staker];
      if (user.lastCheckpoint == 0) { return 0; }
      return (block.timestamp - user.lastCheckpoint) * (baseYield * user.stakedVault.length) / SECONDS_IN_DAY;
    }

    /**
    * @dev Aggregates accumulated $loomi amount from last snapshot to user total accumulatedAmount
    */
    function accumulate(address staker) internal {
      _stakers[staker].accumulatedAmount += getCurrentReward(staker);
      _stakers[staker].lastCheckpoint = block.timestamp;
    }

    /**
    * @dev Returns token owner address (returns address(0) if token is not inside the gateway)
    */
    function ownerOf(uint256 tokenId) public view returns (address) {
      return _ownerOfToken[tokenId];
    }

    function updateCreepzRestriction(bool _restrict) public onlyOwner {
      creepzRestriction = _restrict;
    }

    /**
    * @dev Function allows admin withdraw ERC721 in case of emergency.
    */
    function emergencyWithdraw(address tokenAddress, uint256[] memory tokenIds) public onlyOwner {
      require(tokenIds.length <= 50, "50 is max per tx");
      for (uint256 i; i < tokenIds.length; i++) {
        address receiver = _ownerOfToken[tokenIds[i]];
        if (receiver != address(0) && IERC721(tokenAddress).ownerOf(tokenIds[i]) == address(this)) {
          IERC721(tokenAddress).transferFrom(address(this), receiver, tokenIds[i]);
          emit WithdrawStuckERC721(receiver, tokenAddress, tokenIds[i]);
        }
      }
    }

    /**
    * @dev Function allows to pause deposits if needed. Withdraw remains active.
    */
    function pause(bool _pause) public onlyOwner {
      isPaused = _pause;
    }

    /**
    * @dev Function allows admin to update the base yield for users.
    */
    function updateBaseYield(uint256 _yield) public onlyOwner {
      baseYield = _yield;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns(bytes4){
      return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}