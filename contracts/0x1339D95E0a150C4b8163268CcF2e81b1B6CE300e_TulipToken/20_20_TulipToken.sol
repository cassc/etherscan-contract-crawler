// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/ITulipToken.sol";
import "../libraries/ERC2981.sol";

contract TulipToken is Ownable, ERC721, ERC2981, ITulipToken {
    using SafeERC20 for IERC20;

    uint256 public toBeMinted;

    mapping(address => bool) public controllers;
    mapping(address => uint256[]) public tokensToBeMintedByAddress;

    event ContollerUpdated(address indexed minter, bool role);
    event BaseURIChanged(string baseURI);
    event DefaultRoyaltyChanged(address _receiver, uint96 _feeNumerator);

    /// @notice Initializes the contract with base uri and royalties.
    constructor(
        string memory _uri,
        address _royaltyReceiver,
        uint96 _royaltyFeeNumerator
    ) public ERC721("TulipArt", "TULIP") {
        _setBaseURI(_uri);
        _setDefaultRoyalty(_royaltyReceiver, _royaltyFeeNumerator);
    }

    /// @notice Sets the token winner and the token id
    /// @param _winner: address of the token winner.
    function setTokenWinner(address _winner)
        external
        override
        onlyController
        returns (uint256)
    {
        uint256 _id = _incrementToBeMinted();
        tokensToBeMintedByAddress[_winner].push(_id);
        return _id;
    }

    /// @notice Mint all NFTs won by the sender.
    function claimAll() external override {
        for (
            uint256 i = 0;
            i < tokensToBeMintedByAddress[msg.sender].length;
            ++i
        ) {
            uint256 tokenIdToMint = tokensToBeMintedByAddress[msg.sender][i];
            _mint(msg.sender, tokenIdToMint);
        }

        // Clear the array
        delete tokensToBeMintedByAddress[msg.sender];
    }

    /// @notice Burn burns the specified token owned by the message sender
    /// @param _tokenId: id of the token being burned
    function burn(uint256 _tokenId) external override{
        require(_exists(_tokenId), "TulipToken/nonexistent-token");
        require(ownerOf(_tokenId) == msg.sender, "TulipToken/burn-of-token-that-is-not-own");

        _burn(_tokenId);
    }

    /// @notice This is a function which needs to be handled carefully therefore the
    /// Owner of the contract should be Timelocked contract.
    /// @param _controller: address of a controller to have their role updated
    /// @param _role: bool value with regards to status of an address
    function changeControllerRole(address _controller, bool _role)
        external
        override
        onlyOwner
    {
        require(
            controllers[_controller] != _role,
            "TulipToken/role-already-set"
        );
        controllers[_controller] = _role;
        emit ContollerUpdated(_controller, _role);
    }

    /// @notice This function removes tokens sent to this contract.
    /// @param _token: address of the token to remove from this contract.
    /// @param _to: address of the location to send this token.
    /// @param _amount: amount of tokens to remove from this contract.
    function recoverTokens(
        address _token,
        address _to,
        uint256 _amount
    ) external override onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
    }

    /// @notice View function to check if an address is a controller
    /// of this contract. A controller is an address which can
    /// set the token IDs.
    /// @return returns if an address is a controller or not.
    function isController(address _controllerAddress)
        external
        view
        override
        returns (bool)
    {
        return controllers[_controllerAddress];
    }

    /// @param _baseURI: base URI that points to token data.
    function setBaseURI(string memory _baseURI) public override onlyOwner {
        _setBaseURI(_baseURI);
        emit BaseURIChanged(_baseURI);
    }

    /// @return the tokens that can be minter by the sender.
    function tokensWinner() public view returns (uint256[] memory) {
        return tokensToBeMintedByAddress[msg.sender];
    }

    /// @param _royaltyReceiver: the address receiving the royalties.
    /// @param _royaltyFeeNumerator: the fee taken per trade in basis points.
    function setDefaultRoyalty(
        address _royaltyReceiver,
        uint96 _royaltyFeeNumerator
    ) public override onlyOwner {
        _setDefaultRoyalty(_royaltyReceiver, _royaltyFeeNumerator);
        emit DefaultRoyaltyChanged(_royaltyReceiver, _royaltyFeeNumerator);
    }

    /// @notice Internal function helping to keep track of tokens to be minted.
    /// We need this variable as total minted tokens is not going to be
    /// equal to total tokens to be minted as users might not always claim
    /// the NFT. This is a way to keep track of the IDs to be issued.
    function _incrementToBeMinted() internal returns (uint256) {
        toBeMinted = toBeMinted.add(1);
        return toBeMinted;
    }

    modifier onlyController() {
        require(controllers[msg.sender], "TulipToken/not-a-controller");
        _;
    }
}