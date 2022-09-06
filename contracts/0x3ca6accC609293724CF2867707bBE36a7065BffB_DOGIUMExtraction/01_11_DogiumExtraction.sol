// SPDX-License-Identifier: MIT

/*
Telegram Portal: https://t.me/ShibaDoge_Portal
Website: https://realshibadoge.com & https://warzone.realshibadoge.com/operation-dogium-extraction
Twitter: https://twitter.com/RealShibaDoge
Medium: https://realshibadoge.medium.com
Discord: https://discord.gg/realshibadoge
                                                 
                   ██████╗  ██████╗  ██████╗ ██╗██╗   ██╗███╗   ███╗                               
                   ██╔══██╗██╔═══██╗██╔════╝ ██║██║   ██║████╗ ████║                               
                   ██║  ██║██║   ██║██║  ███╗██║██║   ██║██╔████╔██║                               
                   ██║  ██║██║   ██║██║   ██║██║██║   ██║██║╚██╔╝██║                               
                   ██████╔╝╚██████╔╝╚██████╔╝██║╚██████╔╝██║ ╚═╝ ██║                               
                   ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝ ╚═════╝ ╚═╝     ╚═╝                               
                                                                                
    ███████╗██╗  ██╗████████╗██████╗  █████╗  ██████╗████████╗██╗ ██████╗ ███╗   ██╗
    ██╔════╝╚██╗██╔╝╚══██╔══╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║
    █████╗   ╚███╔╝    ██║   ██████╔╝███████║██║        ██║   ██║██║   ██║██╔██╗ ██║
    ██╔══╝   ██╔██╗    ██║   ██╔══██╗██╔══██║██║        ██║   ██║██║   ██║██║╚██╗██║
    ███████╗██╔╝ ██╗   ██║   ██║  ██║██║  ██║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║
    ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝

*/



import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";


pragma solidity ^0.8.13;

contract DOGIUMExtraction is Ownable, Pausable, ReentrancyGuard {
    IERC721 public DOGE_NFT;
    IERC721 public SHIBA_NFT;

    IERC20 public ShibaDoge;
    IERC20 public Burn;

    address public treasury;

    address public signerAddress;

    bool public stakingLaunched;
    uint256 public stakingEndTime;

    bool public depositPaused;
    bool public isWithdrawPaused;

    struct Staker {
      uint256 currentYield;
      uint256 accumulatedAmount;
      uint256 lastCheckpoint;
      uint256[] stakedDOGE;
      uint256[] stakedSHIBA;
    }

    uint256 rewardMultiplier =  10 ** 3;

    enum ContractTypes {
      DOGE,
      SHIBA
    }

    mapping(address => uint256) public _baseRates;
    mapping(address => Staker) private _stakers;
    mapping(address => mapping(uint256 => address)) private _ownerOfToken;
    mapping(address => ContractTypes) private _contractTypes;
    mapping(address => mapping(uint256 => uint256)) private _nftYield;

    mapping(address => uint256) public spentAmount;

    event Deposit(address indexed staker,address contractAddress,uint256 tokensAmount);
    event Withdraw(address indexed staker,address contractAddress,uint256 tokensAmount);
    event WithdrawStuckERC721(address indexed receiver, address indexed tokenAddress, uint256 indexed tokenId);
    event WithdrawRewards(address indexed staker, uint256 tokens);

    constructor(
      address _DOGE,
      address _SHIBA,
      address _SHIBDOGE_TOKEN,
      address _BURN_TOKEN,
      address _treasury,
      uint256 _baserate
    ) {
        DOGE_NFT = IERC721(_DOGE);
        _contractTypes[_DOGE] = ContractTypes.DOGE;
        _baseRates[_DOGE] = _baserate;

        SHIBA_NFT = IERC721(_SHIBA);
        _contractTypes[_SHIBA] = ContractTypes.SHIBA;
        _baseRates[_SHIBA] = _baserate;

        ShibaDoge = IERC20(_SHIBDOGE_TOKEN);
        Burn = IERC20(_BURN_TOKEN);

        signerAddress = 0x5aBEF98fdD9a83B1c8C90224F86673959C19C701; // frontend signing address

        treasury = _treasury;
    }

    
    /**
    * @dev Function allows admin to pause reward withdraw.
    */
    function pauseWithdraw(
    bool _pause) external onlyOwner {
      isWithdrawPaused = _pause;
    }

    function depositBoth(
      uint256[] memory dogeIds,
      uint256[] memory dogeTraits,
      bytes calldata dogeSignature,
      uint256[] memory shibaIds,
      uint256[] memory shibaTraits,
      bytes calldata shibaSignature)
      external {
        deposit(address(DOGE_NFT), dogeIds, dogeTraits, dogeSignature);
        deposit(address(SHIBA_NFT), shibaIds, shibaTraits, shibaSignature);
    }

    function deposit(
      address contractAddress,
      uint256[] memory tokenIds,
      uint256[] memory tokenTraits,
      bytes calldata signature
    ) public nonReentrant {
      require(!depositPaused, "Deposit paused");
      require(stakingLaunched, "Staking is not launched yet");
      require(block.timestamp < stakingEndTime, "Staking has ended");
      require(
        contractAddress == address(DOGE_NFT)
        || contractAddress == address(SHIBA_NFT),
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

        newYield += getTokenYield(contractAddress, tokenIds[i]);

        if (contractType == ContractTypes.DOGE) { user.stakedDOGE.push(tokenIds[i]); }
        if (contractType == ContractTypes.SHIBA) { user.stakedSHIBA.push(tokenIds[i]); }
      }

      accumulate(_msgSender());
      user.currentYield = newYield;

      emit Deposit(_msgSender(), contractAddress, tokenIds.length);
    }
    
    function withdrawBoth(
      uint256[] memory dogeIds,
      uint256[] memory shibaIds)
      external {
        withdraw(address(DOGE_NFT), dogeIds);
        withdraw(address(SHIBA_NFT), shibaIds);
    }

    function withdraw(
      address contractAddress,
      uint256[] memory tokenIds
    ) public nonReentrant {
      require(
        contractAddress == address(DOGE_NFT)
        || contractAddress == address(SHIBA_NFT),
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

        if (contractType == ContractTypes.DOGE) {
          user.stakedDOGE = _moveTokenInTheList(user.stakedDOGE, tokenIds[i]);
          user.stakedDOGE.pop();
        }

        if (contractType == ContractTypes.SHIBA) {
          user.stakedSHIBA = _moveTokenInTheList(user.stakedSHIBA, tokenIds[i]);
          user.stakedSHIBA.pop();
        }

        IERC721(contractAddress).safeTransferFrom(address(this), _msgSender(), tokenIds[i]);
      }

      if (user.stakedDOGE.length == 0 && user.stakedSHIBA.length == 0) {
        newYield = 0;
      }

      accumulate(_msgSender());
      user.currentYield = newYield;

      emit Withdraw(_msgSender(), contractAddress, tokenIds.length);
    }

    function getTokenYield(address contractAddress, uint256 tokenId) public view returns (uint256) {
      uint256 tokenYield = _nftYield[contractAddress][tokenId];
      if (tokenYield == 0) { tokenYield = _baseRates[contractAddress]; }

      return tokenYield;
    }

    function getStakerYield(address staker) public view returns (uint256) {
      return _stakers[staker].currentYield;
    }

    function getStakerTokens(address staker) public view returns (uint256[] memory, uint256[] memory) {
      return (_stakers[staker].stakedDOGE, _stakers[staker].stakedSHIBA);
    }

    function isTokenYieldSet(address contractAddress, uint256 tokenId) public view returns (bool) {
      return _nftYield[contractAddress][tokenId] > 0;
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
        if (tokenTraits[i] != 0) {
          _nftYield[contractAddress][tokenIds[i]] = tokenTraits[i];
        }
      }
    }

    function getCurrentReward(address staker) public view returns (uint256) {
      Staker memory user = _stakers[staker];
      if (user.lastCheckpoint == 0) { return 0; }


      return (Math.min(block.timestamp, stakingEndTime) - user.lastCheckpoint) * user.currentYield / 1 days;
    }

    function accumulate(address staker) internal { 
      _stakers[staker].accumulatedAmount += getCurrentReward(staker);
      _stakers[staker].lastCheckpoint = Math.min(block.timestamp, stakingEndTime);
    }

    /**
    * @dev Returns token owner address (returns address(0) if token is not inside the gateway)
    */
    function ownerOf(address contractAddress, uint256 tokenId) public view returns (address) {
      return _ownerOfToken[contractAddress][tokenId];
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
          IERC721(tokenAddress).safeTransferFrom(address(this), receiver, tokenIds[i]);
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

    function updateSignerAddress(address _signer) public onlyOwner {
      signerAddress = _signer;
    }

    function updateTreasuryAddress(address _treasury) public onlyOwner {
      treasury = _treasury;
    }

    function launchStaking() public onlyOwner {
      require(!stakingLaunched, "Staking has been launched already");
      stakingLaunched = true;
      stakingEndTime = block.timestamp + 120 days;
    }

    function updateBaseYield(address _contract, uint256 _yield) public onlyOwner {
      _baseRates[_contract] = _yield;
    }

    function setStakingEndTime(uint256 endTime) external onlyOwner {
      require(endTime > stakingEndTime);
      stakingEndTime = endTime;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns(bytes4){
      return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    /**
    * @dev Function to withdraw staked rewards
    */
    function withdrawRewards() public nonReentrant whenNotPaused {
      require(!isWithdrawPaused, "Withdraw Paused");

      uint256 amount = getUserBalance(_msgSender());
      require(amount > 0, "Insufficient balance");

      spentAmount[_msgSender()] += amount;
      ShibaDoge.transferFrom(treasury, _msgSender(), amount * rewardMultiplier);
      Burn.transferFrom(treasury, _msgSender(), amount);

      emit WithdrawRewards(
        _msgSender(),
        amount
      );
    }
 

    /**
    * @dev user's lifetime earnings
    */
    function getAccumulatedAmount(address staker) public view returns (uint256) {
      return _stakers[staker].accumulatedAmount + getCurrentReward(staker);
    }

    /**
    * @dev Returns current withdrawable balance of a specific user.
    */
    function getUserBalance(address user) public view returns (uint256) {
      return (getAccumulatedAmount(user) - spentAmount[user]);
    }

    // Safety functions

    /**
    * @dev Allows owner to withdraw any ERC20 Token sent directly to the contract
    */
    function rescueTokens(address _stuckToken) external onlyOwner {
      uint256 balance = IERC20(_stuckToken).balanceOf(address(this));
      IERC20(_stuckToken).transfer(msg.sender, balance);
    }

    /**
    * @dev Allows owner to withdraw any ERC721 Token sent directly to the contract
    */
    function rescueNFT(address _stuckToken, uint256 id) external onlyOwner {
      if(_stuckToken == address(DOGE_NFT) || _stuckToken == address(SHIBA_NFT)) {
        require( _ownerOfToken[_stuckToken][id] == address(0));
      }
      IERC721(_stuckToken).safeTransferFrom(address(this), msg.sender, id);
    }

}