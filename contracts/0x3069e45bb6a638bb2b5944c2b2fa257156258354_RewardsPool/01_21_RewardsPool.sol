pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "erc721a/contracts/extensions/IERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract RewardsPool is Ownable, ReentrancyGuard {
    address public token;

    address public nftFoxGarden;

    address public nftLittlemami;

    address public nft313Rabbit;

    bool public access;

    uint256 public round;

    using SafeERC20 for IERC20;

    using Strings for uint256;

    mapping(uint256 => uint256) public rewards;

    mapping(address => mapping(uint256 => uint256)) public tokenIdClaimed;

    modifier checkAccess() {
        require(access, "Can't access");
        _;
    }

    modifier checkNFT(address _nft, uint256[] calldata _tokenIds) {
        {
            string memory name = IERC721AQueryable(_nft).name();
            require(
                _tokenIds.length > 0,
                string(abi.encodePacked("You don't have enough ", name))
            );
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                require(
                    IERC721AQueryable(_nft).ownerOf(_tokenIds[i]) ==
                        _msgSender(),
                    string(
                        abi.encodePacked(
                            "You must be ",
                            name,
                            " tokenId ",
                            _tokenIds[i].toString(),
                            " owner"
                        )
                    )
                );
                require(
                    tokenIdClaimed[_nft][_tokenIds[i]] < round,
                    string(
                        abi.encodePacked(
                            "The ",
                            name,
                            " tokenId ",
                            _tokenIds[i].toString(),
                            " you hold has been claimed in this round"
                        )
                    )
                );
                tokenIdClaimed[_nft][_tokenIds[i]] = round;
            }
        }

        _;
    }

    constructor() {
  
        //dai
        token = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        nftFoxGarden = 0x91db548c2770aa04d45e55F5eC3d03Cd094fa1C3;
        nftLittlemami = 0xd6591bBb8A4867cEa5ec732f9c30379C4A8bE730;
        nft313Rabbit = 0xa38450B7503F33c803b43539485df45377758E17;
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
        address _nftLittlemami,
        address _nft313Rabbit
    ) external onlyOwner {
        token = _token;
        nftFoxGarden = _nftFoxGarden;
        nftLittlemami = _nftLittlemami;
        nft313Rabbit = _nft313Rabbit;
    }

    function startRound() external onlyOwner {
        round++;
        access = true;
    }

    function stopRound() external onlyOwner {
        access = false;
    }

    function claim0(
        uint256[] calldata _foxTokenIds
    ) external checkAccess checkNFT(nftFoxGarden, _foxTokenIds) nonReentrant {
        IERC20(token).safeTransfer(
            _msgSender(),
            _foxTokenIds.length *
                rewards[0] *
                10 ** IERC20Metadata(token).decimals()
        );
    }

    function claim1(
        uint256[] calldata _foxTokenIds,
        uint256[] calldata _rabbitTokenIds
    )
        external
        checkAccess
        checkNFT(nftFoxGarden, _foxTokenIds)
        checkNFT(nft313Rabbit, _rabbitTokenIds)
        nonReentrant
    {
        require(
            _foxTokenIds.length == _rabbitTokenIds.length,
            "TokenIds length must be equal"
        );
        IERC20(token).safeTransfer(
            _msgSender(),
            _foxTokenIds.length *
                rewards[1] *
                10 ** IERC20Metadata(token).decimals()
        );
    }

    function claim2(
        uint256[] calldata _foxTokenIds,
        uint256[] calldata _mamiTokenIds
    )
        external
        checkAccess
        checkNFT(nftFoxGarden, _foxTokenIds)
        checkNFT(nftLittlemami, _mamiTokenIds)
        nonReentrant
    {
        require(
            _foxTokenIds.length == _mamiTokenIds.length,
            "TokenIds length must be equal"
        );
        IERC20(token).safeTransfer(
            _msgSender(),
            _foxTokenIds.length *
                rewards[2] *
                10 ** IERC20Metadata(token).decimals()
        );
    }

    function claim3(
        uint256[] calldata _foxTokenIds,
        uint256[] calldata _rabbitTokenIds,
        uint256[] calldata _mamiTokenIds
    )
        external
        checkAccess
        checkNFT(nftFoxGarden, _foxTokenIds)
        checkNFT(nft313Rabbit, _rabbitTokenIds)
        checkNFT(nftLittlemami, _mamiTokenIds)
        nonReentrant
    {
        require(
            _foxTokenIds.length == _rabbitTokenIds.length &&
                _mamiTokenIds.length == _rabbitTokenIds.length,
            "TokenIds length must be equal"
        );
        IERC20(token).safeTransfer(
            _msgSender(),
            _mamiTokenIds.length *
                rewards[3] *
                10 ** IERC20Metadata(token).decimals()
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