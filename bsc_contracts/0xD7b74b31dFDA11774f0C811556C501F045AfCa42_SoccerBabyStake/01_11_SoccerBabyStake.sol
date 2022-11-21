// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity ^0.8.7;

interface INFT721A{
    function getHoldTokenIdsByOwner(address _owner) external view returns (uint256[] memory);
    function ownerOf(uint256 tokenId) external view  returns (address);
}

contract SoccerBabyStake is  Ownable, ReentrancyGuard {

    address public NftContract = 0xaecB4DE0d388C449C08d263C662d5bCA6682d4CA;
    address public tokenContract = 0xFBb105E4a9Ef7c7dA66a278b57D047EC0b3E033b;
    uint256 public constant SECONDS_IN_DAY = 24 * 60 * 60;
    uint256 public _baseRates;
    bool public depositPaused=true;

    struct Staker {
        uint256 currentYield;
        uint256 accumulatedAmount;
        uint256 lastCheckpoint;
        uint256[] stakedNft;
    }

    mapping(address => Staker) private _stakers;
    mapping(uint256 => address) private _ownerOfToken;
    mapping(address => uint256) public tokenRates;

    constructor() {
        _baseRates  = 200000000 ether;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function depositNft(
        uint256[] memory tokenIds
    ) public nonReentrant callerIsUser {
        require(!depositPaused, "Deposit paused");
        Staker storage user = _stakers[_msgSender()];
        uint256 newYield = user.currentYield;

        for (uint256 i; i < tokenIds.length; i++) {
            require(IERC721(NftContract).ownerOf(tokenIds[i]) == _msgSender(), "Not the owner");
            IERC721(NftContract).safeTransferFrom(_msgSender(), address(this), tokenIds[i]);
            _ownerOfToken[tokenIds[i]] = _msgSender();
            newYield += _baseRates;
            user.stakedNft.push(tokenIds[i]);
        }
        accumulate(_msgSender());
        user.currentYield = newYield;
    }


    function withdrawNft(
        uint256[] memory tokenIds
    ) public nonReentrant callerIsUser {
        Staker storage user = _stakers[_msgSender()];
        uint256 newYield = user.currentYield;

        for (uint256 i; i < tokenIds.length; i++) {
            require(IERC721(NftContract).ownerOf(tokenIds[i]) == address(this), "Not the owner");
            _ownerOfToken[tokenIds[i]] = address(0);
            if (user.currentYield != 0) {
                newYield -= _baseRates;
            }

            if (user.stakedNft.length > 1){
                user.stakedNft = _moveTokenInTheList(user.stakedNft, tokenIds[i]);
            }

            user.stakedNft.pop();
            IERC721(NftContract).safeTransferFrom(address(this), _msgSender(), tokenIds[i]);
        }

        if (user.stakedNft.length == 0) {
            newYield = 0;
        }

        accumulate(_msgSender());
        user.currentYield = newYield;
    }

    function CliamToken() public nonReentrant callerIsUser {
        Staker storage user = _stakers[_msgSender()];
        accumulate(_msgSender());
        (bool success,) = tokenContract.call(
            abi.encodeWithSignature("transfer(address,uint256)",msg.sender, user.accumulatedAmount)
        );
        require(success, "call failed");
        user.accumulatedAmount==0;
    }


    function getAccumulatedAmount(address staker) public view returns (uint256) {
        return _stakers[staker].accumulatedAmount + getCurrentReward(staker);
    }

    function getStakerYield(address staker) public view returns (uint256) {
        return _stakers[staker].currentYield;
    }

    function getStakerTokens(address staker) public view returns (uint256[] memory) {
        return _stakers[staker].stakedNft;
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


    function getCurrentReward(address staker) public view returns (uint256) {
        Staker memory user = _stakers[staker];
        if (user.lastCheckpoint == 0) { return 0; }
        return (block.timestamp - user.lastCheckpoint) * user.currentYield / SECONDS_IN_DAY;
    }

    function accumulate(address staker) internal {
        _stakers[staker].accumulatedAmount += getCurrentReward(staker);
        _stakers[staker].lastCheckpoint = block.timestamp;
    }


    function setNftContract(address _nftContract) external onlyOwner {
        NftContract = _nftContract;
    }


    function setTokenContract(address _tokenContract) external onlyOwner {
        tokenContract = _tokenContract;
    }

    /**
    * @dev Returns token owner address (returns address(0) if token is not inside the gateway)
    */
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _ownerOfToken[tokenId];
    }

    function setBaseRates(uint256 _baseReward) public onlyOwner {
        _baseRates = _baseReward;
    }

    /**
    * @dev Function allows admin withdraw ERC721 in case of emergency.
    */
    function emergencyWithdraw(uint256[] memory tokenIds) public onlyOwner {
        require(tokenIds.length <= 50, "50 is max per tx");
        pauseDeposit(true);
        for (uint256 i; i < tokenIds.length; i++) {
            address receiver = _ownerOfToken[tokenIds[i]];
            if (receiver != address(0) && IERC721(NftContract).ownerOf(tokenIds[i]) == address(this)) {
                IERC721(NftContract).transferFrom(address(this), receiver, tokenIds[i]);
            }
        }
    }


    /**
    * @dev Function allows to pause deposits if needed. Withdraw remains active.
    */
    function pauseDeposit(bool _pause) public onlyOwner {
        depositPaused = _pause;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns(bytes4){
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function withdrawToken(uint256 amount) external onlyOwner {
        (bool success,) = tokenContract.call(
            abi.encodeWithSignature("transfer(address,uint256)", payable(msg.sender), amount)
        );
        require(success, "call failed");
    }

    receive() external payable {}

}