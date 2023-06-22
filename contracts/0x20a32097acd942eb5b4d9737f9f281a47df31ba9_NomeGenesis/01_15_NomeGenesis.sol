// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/*
                                            ..:^~~~!!~~~^::.
                                      .^7J5GB##&&&&&&&&&&##BG5J7^.           .7Y5Y7.
                                  .~JP#&&&&&&&&&&&&&&&&&&&&&&&&&&#PJ~.      :B&&&&&G.
                               :75#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#57.   ^#@&&&&B:
                             ^Y#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#Y^  ^JPGPJ:
                           ~P&&&&&&&&&&&&&&&BPYJ7!!~~!!7JYPB&&&&&&&&&&&&&&&P~
                         :5&&&&&&&&&&&&&#57^.              .^75B&&&&&&&&&&&&&5:
                        7#&&&&&&&&&&&&P7.                      .!P&&&&&&&&&&&&#7
                      .5&&&&&&&&&&&&G~                            ~P&&&&&&&&&&&&Y
                     .P&&&&&&&&&&&#?                                7#&&&&&&&&&&&5.
                     P&&&&&&&&&&&#~                                  ^B&&&&&&&&&&&5
                    Y&&&&&&&&&&&#~                                    ^#&&&&&&&&&&&?
                   ~&&&&&&&&&&&&7                                      !&&&&&&&&&&&#^
                   G&&&&&&&&&&&P                                        5&&&&&&&&&&&5
                  ~&&&&&&&&&&&&~                                        ^&&&&&&&&&&&#^
                  Y&&&#GPG#&&&B.                                         G&&&GPPG#&&&?
                  P&#?.   :Y&&5                                          [email protected]^    :Y&&5
                  G&5       B&Y                                          J&^       B&P
                  B&B~     ?&&Y                                          [email protected]    .?&&P
                  G&&#PYJYB&&&5                                          Y&&#5YJ5B&&&Y
                  Y&&&&&&&&&&&G.                                         G&&&&&&&&&&&?
                  ~&&&&&&&&&&&#~                                        ^&&&&&&&&&&&#:
                   G&&&&&&&&&&&5                                        5&&&&&&&&&&&5
                   !&&&&&&&&&&&#7                                      !&&&&&&&&&&&#^
                    [email protected]&&&&&&&&&&B^                                    ^#&&&&&&&&&&&?
                     [email protected]&&&&&&&&&&B~                                  ^B&&&&&&&&&&&Y
                     [email protected]&&&&&&&&&&#7                                7#&&&&&&&&&&&5
                      [email protected]&&&&&&&&&&&P~                            ~P&&&&&&&&&&&&J
                        ?#@&&&&&&&&&&&P!.                      .!P&&&&&&&&&&&@B!
                         :5&&&&&&&&&&&&&B57^.              .^75#&&&&&&&&&&&@&Y.
                    ...    ~P&@&&&&&&&&&&&&&BPYJ7!!~!!!7JYPB&@@&&&&&&&&&&@&5^
                  7GB#B5^    ^5#@@&&&&&&&&&&&&@@&&&&&&&@@@&&&&&&&&&&&&@&BJ^
                 [email protected]@&&&&B.     .7P#&@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@&#5!.
                 ^[email protected]@@&#J         .!JG#&@@@&&&&&&&&&&&&&&&&&&@@@&BPJ~.
                  .~??!:              .^7J5GB#&&&&&&&&&&&&#BG5J!^.
                                            ..:^^~~~~~~^^:.
*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

error MintIncorrectPrice();
error MintNotEnoughAvailable();
error MintBatchSizeTooHigh();

contract NomeGenesis is ERC721A, Ownable, Pausable, PaymentSplitter {
    uint256 public maxBatchSize;
    uint256 public maxTokens;
    uint256 public mintPrice;
    string private _baseTokenURI;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        uint256 _mintPrice,
        uint256 _maxTokens,
        uint256 _maxBatchSize,
        address[] memory _payees,
        uint256[] memory _shares
    ) payable ERC721A(_name, _symbol) PaymentSplitter(_payees, _shares) {
        mintPrice = _mintPrice;
        maxTokens = _maxTokens;
        maxBatchSize = _maxBatchSize;
        _baseTokenURI = _baseUri;
    }

    function mint(uint256 _amount) external payable {
        if (msg.value != (mintPrice * _amount)) revert MintIncorrectPrice();
        if (_amount > tokensAvailable()) revert MintNotEnoughAvailable();
        if (_amount > maxBatchSize) revert MintBatchSizeTooHigh();
        _safeMint(_msgSender(), _amount);
    }

    function mintTo(address _to, uint256 _amount) external onlyOwner {
        if (_amount > tokensAvailable()) revert MintNotEnoughAvailable();
        if (_amount > maxBatchSize) revert MintBatchSizeTooHigh();
        _safeMint(_to, _amount);
    }

    function tokensAvailable() private view returns (uint256) {
        return maxTokens - _totalMinted();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenNotPaused {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}