// SPDX-License-Identifier: GPL-3.0
// Author: Participants; Developed by Modern People, 2022

pragma solidity ^0.8.12;
import "./extensions/ERC721Enum.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./ParticipantsRoyaltySplitter.sol";
import "./interfaces/IParticipantsERC20Tokens.sol";

contract Participants is
    ERC721Enum,
    Ownable,
    ReentrancyGuard,
    IERC2981,
    IParticipantsERC20Tokens
{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 internal constant ROYALTY_BASE = 10000;
    uint256 internal constant ROYALTY_PERC = 500;

    bool public isMintingActive = false;
    string internal _baseTokenURI;
    address public participantsRoyaltyContract;

    address[] internal _erc20Tokens;

    // bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address[] memory _recipients, //comm,mp,dd
        uint256[] memory _splits,
        address[] memory _tokens
    ) ERC721P(_name, _symbol) {
        setBaseURI(_initBaseURI);
        _erc20Tokens = _tokens;
        participantsRoyaltyContract = address(
            new ParticipantsRoyaltySplitter(_recipients, _splits, address(this))
        );
    }

    // internal
    function _baseURI() internal view virtual returns (string memory) {
        return _baseTokenURI;
    }

    // public minting
    function mint() external {
        require(isMintingActive, "MintingNotActive");
        require(balanceOf(msg.sender) == 0, "OnePerWallet.");

        uint256 _totalSupply = totalSupply();
        require(_totalSupply + 1 <= MAX_SUPPLY, "Sold Out");

        _mint(msg.sender, _totalSupply + 1);
        delete _totalSupply;
    }

    function reserve() external onlyOwner {
        uint256 _totalSupply = totalSupply();
        uint256 _amount = 33;
        for (uint256 i = 0; i < _amount; ++i) {
            _mint(msg.sender, _totalSupply + i);
        }
    }

    function royaltyInfo(uint256, uint256 _salePrice)
        public
        view
        override(IERC2981)
        returns (address receiver, uint256 royaltyAmount)
    {
        return (
            participantsRoyaltyContract,
            (_salePrice * ROYALTY_PERC) / ROYALTY_BASE
        );
    }

    // admin functionality

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "NonexistentToken");
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function setMintingStatus(bool _status) external onlyOwner {
        isMintingActive = _status;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enum, IERC165)
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }

    function setRoyaltyERC20Tokens(address[] calldata _tokens)
        public
        onlyOwner
    {
        _erc20Tokens = _tokens;
    }

    function getRoyaltyERC20Tokens()
        public
        view
        returns (address[] memory tokens)
    {
        return _erc20Tokens;
    }

    function withdraw() external payable {
        for (uint256 index = 0; index < _erc20Tokens.length; index++) {
            IERC20 token = IERC20(_erc20Tokens[index]);
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) {
                bool _success = token.transfer(
                    payable(participantsRoyaltyContract),
                    balance
                );
                require(_success, "ERC20TransferFailed.");
            }
        }

        (bool success, ) = payable(participantsRoyaltyContract).call{
            value: address(this).balance
        }("");
        require(success, "ETHTransferFailed");
    }

    receive() external payable {}
}