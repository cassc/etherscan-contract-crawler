// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import 'hardhat/console.sol';

/// @title EarnLabs Pass Contract
/// @author 0xQruz
/// @notice Manage EarnLabs Pass NFT
contract NraeLabPass is ERC721Enumerable, Ownable, ReentrancyGuard, Pausable {
    /*///////////////////////////////////////////////////////////////
                             VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @notice address of treasury
    address public TREASURY;

    /// @notice Token address for payments
    address public TOKEN;

    /// @notice Price of a single pass (in tokens)
    uint256 public MINTING_PRICE = 180;

    /// @notice Maximum supply of passes
    uint256 public MAX_SUPPLY = 500;

    /// @notice Base Token URI
    string public TOKEN_URI = 'https://metadata.earnlab.io/';

    mapping(address => uint256) mintedWallets;

    constructor(address _TOKEN, address _TREASURY) ERC721('NraePass', 'ERNP') {
        TOKEN = _TOKEN;
        TREASURY = _TREASURY;
    }

    /*///////////////////////////////////////////////////////////////
                             MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted after ta user minted a pass
    /// @param _to The address of the user who received the pass
    /// @param _tokenId The ID of the pass that was minted
    event Minted(address indexed _to, uint256 indexed _tokenId);

    /// @notice Emiited after an Airdrop round
    /// @param _to The wallet address that received the airdrop
    /// @param _amount The amount of tokens that were airdropped
    event Airdropped(address indexed _to, uint256 indexed _amount);

    /// @notice Mint a new pass for a given wallet
    /// @param _to address of the wallet to mint for
    function mint(address _to) external nonReentrant whenNotPaused {
        ERC20 token = getToken();
        uint256 tokenBalance = token.balanceOf(address(msg.sender));

        require(tokenBalance >= 1e18 * MINTING_PRICE, 'NOT_ENOUGH_FUNDS');
        require(mintedWallets[_to] == 0, 'ALREADY_MINTED');
        require(MAX_SUPPLY > totalSupply(), 'MAX_SUPPLY_REACHED');

        bool result = token.transferFrom(msg.sender, address(this), 1e18 * MINTING_PRICE);
        require(result, 'TRANSFER FAILED');

        mintedWallets[_to]++;

        uint256 _tokenId = totalSupply() + 1;
        _safeMint(_to, _tokenId);

        emit Minted(_to, _tokenId);
    }

    function airdrop(address _to, uint256 _amount) external onlyOwner nonReentrant whenNotPaused {
        require(MAX_SUPPLY >= totalSupply() + _amount, 'MAX_SUPPLY_REACHED');

        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(_to, tokenId);
        }

        emit Airdropped(_to, _amount);
    }

    /*///////////////////////////////////////////////////////////////
                             PAUSE LOGIC
    //////////////////////////////////////////////////////////////*/

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Varification function
    /// @param _holder address of the user
    /// @return bool corresponding to the user's  holder status
    function verify(address _holder) public view returns (bool) {
        return balanceOf(_holder) > 0;
    }

    /// @notice Setter function for the minting price
    /// @param _mintingPrice New price in simplidifed token units
    function setMintingPrice(uint256 _mintingPrice) public onlyOwner {
        MINTING_PRICE = _mintingPrice;
    }

    /// @notice Setter function for the maximum supply
    /// @param _maxSupply New maximum supply in passes
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        MAX_SUPPLY = _maxSupply;
    }

    /// @notice Setter function for the payment token address
    /// @param _tokenAddress New token address
    function setTokenAddress(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0), 'TOKEN_ADDRESS_IS_ZERO');
        require(_tokenAddress != address(this), 'TOKEN_ADDRESS_IS_SAME_AS_CONTRACT');
        require(_tokenAddress != TOKEN, 'TOKEN_ADDRESS_IS_UNCHANGED');
        TOKEN = _tokenAddress;
    }

    /// @notice Getter function for the payment token interface
    /// @return ERC20 interface of the payment token interface
    function getToken() private view returns (ERC20) {
        return ERC20(TOKEN);
    }

    /*///////////////////////////////////////////////////////////////
                             TREASURY LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted after the owner pull the funds to the treasury address
    /// @param user The authorized user who triggered the withdraw
    /// @param treasury The treasury address to which the funds have been sent
    /// @param amount The amount withdrawn
    event TreasuryWithdraw(address indexed user, address treasury, uint256 amount);

    /// @notice Emitted after the owner pull the funds to the treasury address
    /// @param user The authorized user who triggered the withdraw
    /// @param newTreasury The new treasury address
    event TreasuryUpdated(address indexed user, address newTreasury);

    function setTreasury(address _treasury) external onlyOwner {
        // check that the new treasury address is valid
        require(_treasury != address(0), 'INVALID_TREASURY_ADDRESS');
        require(TREASURY != _treasury, 'SAME_TREASURY_ADDRESS');

        // update the treasury
        TREASURY = _treasury;

        // emit the event
        emit TreasuryUpdated(msg.sender, _treasury);
    }

    function withdrawTreasury() external onlyOwner {
        // calc the amount of balance that can be sent to the treasury
        uint256 amount = getToken().balanceOf(address(this));
        require(amount != 0, 'NO_TREASURY');

        // emit the event
        emit TreasuryWithdraw(msg.sender, TREASURY, amount);

        // Transfer to the treasury
        bool success = getToken().transfer(TREASURY, amount);
        require(success, 'WITHDRAW_FAIL');
    }

    /*///////////////////////////////////////////////////////////////
                             URI LOGIC
    ///////////////////////////////////////////////////////////////*/

    function _baseURI() internal view override returns (string memory) {
        return TOKEN_URI;
    }

    /// @notice Getter function for the token URI
    /// @dev The token URI is composed of the base URI, the holder's address and the token ID
    /// @param _tokenId The token ID
    /// @return The token URI
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return
            string.concat(
                _baseURI(),
                Strings.toHexString(ownerOf(_tokenId)),
                '/',
                Strings.toString(_tokenId)
            );
    }

    /// @notice Setter function for the base token URI
    /// @param _baseTokenURI New token URI
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        TOKEN_URI = _baseTokenURI;
    }
}