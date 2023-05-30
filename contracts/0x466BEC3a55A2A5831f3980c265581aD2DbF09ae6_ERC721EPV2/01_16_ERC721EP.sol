// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*********************************************************************************************************************************************
  _______  _______  _______  ___      ___      _______  ______     __    _  _______  _______   __   __  _______  ___   _  _______  ______   
 |       ||       ||       ||   |    |   |    |   _   ||    _ |   |  |  | ||       ||       | |  |_|  ||   _   ||   | | ||       ||    _ |  
 |  _____||_     _||    ___||   |    |   |    |  |_|  ||   | ||   |   |_| ||    ___||_     _| |       ||  |_|  ||   |_| ||    ___||   | ||  
 | |_____   |   |  |   |___ |   |    |   |    |       ||   |_||_  |       ||   |___   |   |   |       ||       ||      _||   |___ |   |_||_ 
 |_____  |  |   |  |    ___||   |___ |   |___ |       ||    __  | |  _    ||    ___|  |   |   |       ||       ||     |_ |    ___||    __  |
  _____| |  |   |  |   |___ |       ||       ||   _   ||   |  | | | | |   ||   |      |   |   | ||_|| ||   _   ||    _  ||   |___ |   |  | |
 |_______|  |___|  |_______||_______||_______||__| |__||___|  |_| |_|  |__||___|      |___|   |_|   |_||__| |__||___| |_||_______||___|  |_|
           ____  ____   ___     ____  ____   __  ____  ____    _  _  ____ 
          (  __)(  _ \ / __)___(__  )(___ \ /  \(  __)(  _ \  / )( \(___ \
           ) _)  )   /( (__(___) / /  / __/(_/ / ) _)  ) __/  \ \/ / / __/
          (____)(__\_) \___)    (_/  (____) (__)(____)(__)     \__/ (____)

    Special thanks to
        MEGAMI Team ( https://www.megami.io/ )
        ForgottenRunesWarriorsGuild ( https://www.forgottenrunes.com/ )
        Chuck K.

*********************************************************************************************************************************************/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./rarible/royalties/contracts/LibPart.sol";
import "./rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "./rarible/royalties/contracts/RoyaltiesV2.sol";

contract ERC721EPV2 is ERC721, ERC721URIStorage, Ownable, RoyaltiesV2 {
    using Strings for uint256;

    // SNM Finalaize flag
    bool private _final = false;

    // SNM Freez flag
    mapping(uint256 => bool) private _freez;

    // SNM Mint Fee
    uint256 private _mintFee = 0.03 ether;

    // SNM automatic freezing flag
    bool private _autoFreeze = true;

    // Mint upper limit
    uint256 private _maxSupply = 10000;

    // SNM Emergency Mode Flag
    bool private _emergencyLock = false;

    // SNM Multi supporter Addresses
    address[] private supporterAddresses = [
        0xCF9542a8522E685a46007319Af9C39F4Fde9d88a, // SNM Superuser
        0x2fa56A56aB5f3447752fF8D0FcbC88bf2e58B3B6
    ];

    // Total Supply
    uint256 public totalSupply = 0;

    // Royality management
    bytes4 public constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    address payable public defaultRoyaltiesReceipientAddress;  // This will be set in the constructor
    uint96 public defaultPercentageBasisPoints = 1000;  // 10%

    // Finalizing event
    event ContractFinalize(address indexed sender);

    // Constract
    constructor(string memory name, string memory symbol, uint96 royalty, uint256 mintFee)
    ERC721(name, symbol)
    {
        _mintFee = mintFee;
        defaultRoyaltiesReceipientAddress = payable(address(this));
        defaultPercentageBasisPoints = royalty;
    }
    
    /**
     * @dev check supporter for modifier,
     */
    function checkSupporter()
        private
        view
        returns(bool)
    {
        uint256 matchSupporter = 0;
        for (uint i = 0; i < supporterAddresses.length; i++) {
            if(supporterAddresses[i] == msg.sender){
                matchSupporter++;
            }
        }
        return(matchSupporter > 0);
    }

    /**
     * @dev check owner or supporter for modifier,
     */
    function checkAdmin()
        private
        view
        returns(bool)
    {
        return(checkSupporter() || msg.sender == owner());
    }

    /**
     * @dev onlyAdmin modifier
     */
    modifier onlyAdmin()
    {
        require(checkAdmin(), "Ownable: caller is not the Owner or Supporter");
        _;
    }

    /**
     * @dev OnlySupporter modifier
     */
    modifier onlySupporter()
    {
        require(checkSupporter(), "Supportable: caller is not the Supporter");
        _;
    }

    /**
     * @dev EmergencyMode modifier
     */
    modifier emergencyMode()
    {
        require(!_emergencyLock, "Contract Locked");
        _;
    }

    /**
     * @dev append supporter
     */
    function setSupporter(address supporter_)
        public
        onlySupporter
    {
        supporterAddresses.push(supporter_);
    }

    /**
     * @dev change supporter by index
     */
    function setSupporter(address supporter_, uint256 index)
        public
        onlySupporter
    {
        supporterAddresses[index] = supporter_;
    }

    /**
     * @dev get super supporter
     */
    function supporter()
        public
        view
        returns(address)
    {
        return(supporterAddresses[0]);
    }

    /**
     * @dev get supporter by index
     */
    function supporter(uint256 index)
        public
        view
        returns(address)
    {
        return(supporterAddresses[index]);
    }

    /**
     * @dev disable Ownerble renounceOwnership
     */
    function renounceOwnership() public onlyAdmin override {}

    /**
     * @dev ERC721 beforeTokenTransfer
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        virtual
        override
        emergencyMode
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev ERC721 transferFrom
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        virtual
        override(ERC721)
        emergencyMode
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev ERC721 safeTransferFrom
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        virtual
        override(ERC721)
        emergencyMode
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev ERC721 safeTransferFrom
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    )
        public
        virtual
        override(ERC721)
        emergencyMode
    {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev getting latest owner fee.
     */
    function getOwnerFee()
        public
        view
        returns(uint256)
    {
        return address(this).balance;
    }

    /**
     * @dev do withdraw eth.
     */
    function withdrawETH()
        external
        virtual
        onlyAdmin
        emergencyMode
    {
        uint256 royalty = address(this).balance;

        Address.sendValue(payable(owner()), royalty);
    }

    /**
     * @dev checking a self-owned token.
     * @param tokenId token ID
     */
    function tokenOwnerIsCreator(uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return ownerOf(tokenId) == owner();
    }

    /**
     * @dev can change URI of token.
     * @param tokenId token ID
     * @param itemName URI
     */
    function _setTokenURI(uint256 tokenId, string memory itemName)
        internal
        override
        emergencyMode
    {
        super._setTokenURI(tokenId, itemName);
    }

    /**
     * @dev can change URI of token if SuperSupporter.
     * @param tokenId token ID
     * @param uri URI
     */
    function putTokenURI(uint256 tokenId, string memory uri)
        external
        onlySupporter
    {
        require(!_final, "Already Finalized");
        require(tokenOwnerIsCreator(tokenId), "Can not write");
        _setTokenURI(tokenId, uri);
    }

    /**
     * @dev enable automatic freezing.
     */
    function enableAutoFreez()
        public
        virtual
        onlySupporter
    {
        _autoFreeze = true;
    }

    /**
     * @dev disable automatic freezing.
     */
    function disableAutoFreez()
        public
        virtual
        onlySupporter
    {
        _autoFreeze = false;
    }

    /**
     * @dev set SNM plan fee.
     */
    function setMintFee(uint256 fee)
        public
        onlySupporter
    {
        _mintFee = fee;
    }

    /**
     * @dev SNM plan fee.
     */
    function getMintFee()
        external
        view
        returns(uint256)
    {
        return _mintFee;
    }

    /**
     * @dev do minting token [only owner].
     * @param uri URI
     */
    function mint(string memory uri)
        public
        payable
        onlyOwner
        emergencyMode
    {
        require(msg.value >= _mintFee, "Need to send ETH");
        require(!_final, "Already Finalized");
        uint256 currentNumber = totalSupply + 1;

        _safeMint(_msgSender(), currentNumber);
        _setTokenURI(currentNumber, uri);

        Address.sendValue(payable(supporterAddresses[0]), msg.value);

        if(_autoFreeze){
            freezing(currentNumber);
        }

        totalSupply = currentNumber;
    }

    /**
     * @dev do token burn.
     * @param tokenId token ID
     */
    function burn(uint256 tokenId)
        external
        onlyAdmin
        emergencyMode
    {
        _burn(tokenId);
    }

    /**
     * @dev get token URI.
     * @param tokenId token ID
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev do emergency lock.
     */
    function emergencyLock()
        public
        virtual
        onlyAdmin
    {
        _emergencyLock = true;
        _transferOwnership(supporterAddresses[0]);
    }

    /**
     * @dev unlocked emergency lock.
     */
    function emergencyUnLock()
        external
        onlyAdmin
    {
        _emergencyLock = false;
    }

    /**
     * @dev call by burn
     */
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    /**
     * @dev do contract finalizing.
     */
    function finalize()
        public
        virtual
        onlySupporter
    {
        _final = true;
        emit ContractFinalize(_msgSender());
    }

    /**
     * @dev do token freezing.
     * @param tokenId token ID
     */
    function freezing(uint256 tokenId)
        public
        onlyAdmin
        emergencyMode
    {
        _freez[tokenId] = true;
    }

    /**
     * @dev can not change contract if finalizing.
     */
    function isFinalize()
        external
        view
        returns( bool )
    {
        return _final;
    }

    /**
     * @dev can not change token if freezing.
     * @param tokenId token ID
     */
    function isFreezing(uint256 tokenId)
        external
        view
        returns( bool )
    {
        return _freez[tokenId];
    }

    // Copied from ForgottenRunesWarriorsGuild. Thank you dotta ;)
    /**
     * @dev ERC20s should not be sent to this contract, but if someone
     * does, it's nice to be able to recover them
     * @param token IERC20 the token address
     * @param amount uint256 the amount to send
     */
    function forwardERC20s(IERC20 token, uint256 amount) public onlyAdmin {
        require(address(msg.sender) != address(0));
        token.transfer(msg.sender, amount);
    }

    // Royality management
    /**
     * @dev set defaultRoyaltiesReceipientAddress
     * @param _defaultRoyaltiesReceipientAddress address New royality receipient address
     */
    function setDefaultRoyaltiesReceipientAddress(address payable _defaultRoyaltiesReceipientAddress) public onlyAdmin {
        defaultRoyaltiesReceipientAddress = _defaultRoyaltiesReceipientAddress;
    }

    /**
     * @dev set defaultPercentageBasisPoints
     * @param _defaultPercentageBasisPoints uint96 New royality percentagy basis points
     */
    function setDefaultPercentageBasisPoints(uint96 _defaultPercentageBasisPoints) public onlyAdmin {
        defaultPercentageBasisPoints = _defaultPercentageBasisPoints;
    }

    /**
     * @dev return royality for Rarible
     */
    function getRaribleV2Royalties(uint256) external view override returns (LibPart.Part[] memory) {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = defaultPercentageBasisPoints;
        _royalties[0].account = defaultRoyaltiesReceipientAddress;
        return _royalties;
    }

    /**
     * @dev return royality in EIP-2981 standard
     * @param _salePrice uint256 sales price of the token royality is calculated
     */
    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (defaultRoyaltiesReceipientAddress, (_salePrice * defaultPercentageBasisPoints) / 10000);
    }

    /**
     * @dev Interface
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}