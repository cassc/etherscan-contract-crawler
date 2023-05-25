// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract ERC721Mint is ERC721, Ownable {
    string public uri;

    mapping(address => bool) public managers;

    uint public tokenId = 0;

    address public metadata;

    bool public isPaused = false;

    modifier onlyManager() {
        require(
            managers[msg.sender], 
            'ERC721Mint: caller is not the manager'
        );
        _;
    }
    
    constructor(string memory _name, string memory _symbol, string memory _uri) ERC721 (_name, _symbol) {
        uri = _uri;

        managers[msg.sender] = true;
    }

    function _updateManagerList(address _manager, bool _status)
        external
        onlyOwner
        returns(bool)
    {
        managers[_manager] = _status;

        return true;
    }

    function _setPause(bool _isPaused)
        external
        onlyOwner
        returns (bool)
    {
        isPaused = _isPaused;

        return true;
    }

    function mint(address to) 
        external 
        onlyManager
        returns(uint) 
    {
        _mint(to, tokenId);

        tokenId++;

        return tokenId;
    }

    function burn(uint _tokenId) 
        external
        returns(bool) 
    {
        require(msg.sender == ownerOf(_tokenId), 'ERC721Mint:burn: only token owner can be burned');

        _burn(_tokenId);

        return true;
    }

    function _baseURI() 
        internal 
        view 
        override
        returns(string memory) 
    {
        return uri;
    }

    function _setURI(string memory _newURI) 
        external
        onlyOwner
        returns(bool) 
    {
        uri = _newURI;

        return true;
    }

    function _setMetadata(address _metadata) 
        public 
        onlyOwner 
        returns(bool) 
    {
        metadata = _metadata;

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) 
        public 
        virtual 
        override 
    {
        require(!isPaused, 'ERC721Mint::transferFrom: transfers are closed');

        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) 
        public 
        virtual 
        override 
    {
        require(!isPaused, 'ERC721Mint::safeTransferFrom: transfers are closed');

        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function _withdrawERC20(address _token, address _recepient)
        external 
        onlyOwner 
        returns(bool) 
    {
        IERC20(_token).transfer(_recepient, IERC20(_token).balanceOf(address(this)));

        return true;
    }

    function _withdrawERC721(address _token, address _recepient, uint _tokenId)
        external 
        onlyOwner 
        returns(bool) 
    {
        IERC721(_token).transferFrom(address(this), _recepient, _tokenId);

        return true;
    }
}