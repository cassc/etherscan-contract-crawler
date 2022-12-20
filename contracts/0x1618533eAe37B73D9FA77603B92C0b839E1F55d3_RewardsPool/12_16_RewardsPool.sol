pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "erc721a/contracts/extensions/IERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract RewardsPool is Ownable, ReentrancyGuard {
    address public token;

    address public nftFoxGarden;

    address public nftLittlemamipass;

    address public nft313rabbit;

    bool public access;

    uint256 public round;

    using SafeERC20 for IERC20;

    mapping(uint256 => uint256) public rewards;

    mapping(address => mapping(uint256 => uint256)) public tokenIdClaimed;

    mapping(address => uint256) public addressClaimed;

    modifier checkAccess() {
        require(access, "Can't access");
        _;
    }

    modifier checkAddress() {
        require(
            addressClaimed[_msgSender()] < round,
            "You have already claimed in this round"
        );
        addressClaimed[_msgSender()] = round;
        _;
    }

    modifier checkNFT(address _nft) {
        uint256[] memory tokenIds = IERC721AQueryable(_nft).tokensOfOwner(
            _msgSender()
        );
        string memory name = IERC721AQueryable(_nft).name();
        require(
            tokenIds.length > 0,
            string(abi.encodePacked("You don't have enough ", name))
        );
        bool confirmed;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIdClaimed[_nft][tokenIds[i]] < round) {
                confirmed = true;
                tokenIdClaimed[_nft][tokenIds[i]] = round;
            }
        }
        require(
            confirmed,
            string(
                abi.encodePacked(
                    "The ",
                    name,
                    " you hold has been claimed in this round"
                )
            )
        );
        _;
    }

    constructor() {
        //dai
        token = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        nftFoxGarden = 0x91db548c2770aa04d45e55F5eC3d03Cd094fa1C3;
        nftLittlemamipass = 0xd6591bBb8A4867cEa5ec732f9c30379C4A8bE730;
        nft313rabbit = 0xa38450B7503F33c803b43539485df45377758E17;
        rewards[0] = 40;
        rewards[1] = 48;
        rewards[2] = 64;
        rewards[3] = 80;
    }

    function setRewards(uint256[] calldata _rewards) external onlyOwner {
        for (uint256 i = 0; i < 4; i++) {
            rewards[i] = _rewards[i];
        }
    }

    function setAddress(
        address _token,
        address _nftFoxGarden,
        address _nftLittlemamipass,
        address _nft313rabbit
    ) external onlyOwner {
        token = _token;
        nftFoxGarden = _nftFoxGarden;
        nftLittlemamipass = _nftLittlemamipass;
        nft313rabbit = _nft313rabbit;
    }

    function startRound() external onlyOwner {
        round++;
        access = true;
    }

    function stopRound() external onlyOwner {
        access = false;
    }

    function claim0()
        external
        checkAccess
        checkAddress
        checkNFT(nftFoxGarden)
        nonReentrant
    {
        IERC20(token).safeTransfer(
            _msgSender(),
            rewards[0] * 10 ** IERC20Metadata(token).decimals()
        );
    }

    function claim1()
        external
        checkAccess
        checkAddress
        checkNFT(nftFoxGarden)
        checkNFT(nft313rabbit)
        nonReentrant
    {
        IERC20(token).safeTransfer(
            _msgSender(),
            rewards[1] * 10 ** IERC20Metadata(token).decimals()
        );
    }

    function claim2()
        external
        checkAccess
        checkAddress
        checkNFT(nftFoxGarden)
        checkNFT(nftLittlemamipass)
        nonReentrant
    {
        IERC20(token).safeTransfer(
            _msgSender(),
            rewards[2] * 10 ** IERC20Metadata(token).decimals()
        );
    }

    function claim3()
        external
        checkAccess
        checkAddress
        checkNFT(nftFoxGarden)
        checkNFT(nft313rabbit)
        checkNFT(nftLittlemamipass)
        nonReentrant
    {
        IERC20(token).safeTransfer(
            _msgSender(),
            rewards[3] * 10 ** IERC20Metadata(token).decimals()
        );
    }

    function withdrawETH(address payable _to) external onlyOwner {
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawERC20(address _erc20, address _to) external onlyOwner {
        IERC20(_erc20).safeTransfer(
            _to,
            IERC20(_erc20).balanceOf(address(this))
        );
    }

    function withdrawERC721(
        address _erc721,
        address _to,
        uint256[] calldata _tokenIds
    ) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC721A(_erc721).transferFrom(address(this), _to, _tokenIds[i]);
        }
    }

    function withdrawERC1155(
        address _erc1155,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external onlyOwner {
        IERC1155(_erc1155).safeBatchTransferFrom(
            address(this),
            _to,
            _ids,
            _amounts,
            _data
        );
    }
}