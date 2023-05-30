// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC721Tradable.sol";

contract CurrencyPunks is ERC721Tradable {
    using SafeMath for uint256;

    uint256 constant MAX_SUPPLY = 10000;
    uint256 constant FUND_LIMIT = 42;

    uint16 public reservedByHirst = 3100;
    address public fundAddress;
    uint16 public mintedToFund;

    constructor(address fundAddress_, address _proxyRegistryAddress)
        ERC721Tradable("CurrencyPunks", "CUPU", _proxyRegistryAddress)
    {
        fundAddress = fundAddress_;
        _safeMint(address(this), reservedByHirst);
    }

    function baseTokenURI() public pure override returns (string memory) {
        return "ipfs://QmaLbifbepMjtigQ6eGDcmYpMph3fFuKSxopcttn4VERDw/";
    }

    function claimHirst(address damienHirst) public onlyOwner {
        require(damienHirst != _msgSender(), "owner cannot claim");
        require(damienHirst != fundAddress, "fund cannot claim");

        _safeTransfer(address(this), damienHirst, reservedByHirst, "");
    }

    function mint() public {
        require(totalSupply().add(1) <= MAX_SUPPLY, "max supply is reached");
        require(
            balanceOf(_msgSender()) == 0,
            "only one token per address allowed"
        );

        _mintAndSkipReserved(_msgSender());
    }

    function mintToFund() public onlyOwner {
        require(mintedToFund + 1 <= FUND_LIMIT, "fund limit is reached");
        require(totalSupply().add(1) <= MAX_SUPPLY, "max supply is reached");

        _mintAndSkipReserved(fundAddress);
        mintedToFund++;
    }

    function _mintAndSkipReserved(address to_) private {
        uint256 newTokenId = _getNextTokenId();

        while (newTokenId == reservedByHirst) {
            _incrementTokenId();
            newTokenId = _getNextTokenId();
        }

        _safeMint(to_, newTokenId);
        _incrementTokenId();
    }
}