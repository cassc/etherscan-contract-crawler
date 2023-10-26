// SPDX-License-Identifier: MIT
// dev address is 0x67145faCE41F67E17210A12Ca093133B3ad69592
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IStakingPool {
    function startStaking(address _staker, uint256 _tokenId) external;

    function stopStaking(address _staker, uint256 _tokenId) external;
}

contract TentacleKnockout is ERC721Enumerable, Ownable, Pausable {
    using SafeMath for uint256;

    IStakingPool private _pool;

    uint256 public constant MAX_ELEMENTS = 1000;
    uint256 public constant MAX_PUBLIC_MINT = 20;
    uint256 public constant PRICE = 0.25 ether;

    string public baseTokenURI;

    event CreateTentacleKnockout(uint256 indexed id);
    event PoolAddrSet(address addr);

    constructor(string memory baseURI, address _poolAddr)
        ERC721("TentacleKnockout", "TKO")
    {
        setBaseURI(baseURI);
        // pause(true);
        _pool = IStakingPool(_poolAddr);
    }

    modifier notPaused() {
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    /**
     * @dev Mint the _amount of tokens
     * @param _amount is the token count
     */
    function mint(uint256 _amount) public payable notPaused {
        uint256 total = totalSupply();
        require(totalSupply() < MAX_ELEMENTS, "Sale end");
        require(total + _amount <= MAX_ELEMENTS, "Max limit");
        require(
            _amount + balanceOf(msg.sender) <= MAX_PUBLIC_MINT ||
                msg.sender == owner(),
            "Exceeded max token purchase"
        );
        require(msg.value >= price(_amount), "Value below price");

        for (uint256 i = 0; i < _amount; i++) {
            uint256 id = totalSupply();
            _safeMint(msg.sender, id);
            emit CreateTentacleKnockout(id);
        }
    }

    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    function burn(uint256 tokenId) public virtual notPaused {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    /**
     * @dev set the _baseTokenURI
     * @param baseURI of the _baseTokenURI
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
        if (_msgSender() != owner()) {
            require(!paused(), "ERC721Pausable: token transfer while paused");
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*******************************************************************************
     ***                            Staking Logic                                 ***
     ******************************************************************************** */

    function startStaking(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "Staking: owner not matched");

        _pool.startStaking(msg.sender, _tokenId);
        _safeTransfer(msg.sender, address(_pool), _tokenId, "");
    }

    function stopStaking(uint256 _tokenId) external {
        _pool.stopStaking(msg.sender, _tokenId);
        _safeTransfer(address(_pool), msg.sender, _tokenId, "");
    }

    function setStakingPool(address _addr) external onlyOwner {
        _pool = IStakingPool(_addr);
        emit PoolAddrSet(_addr);
    }
}