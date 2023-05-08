//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/ERC721A/contracts/extensions/ERC721AQueryable.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {OperatorFilterer} from "lib/closedsea/src/OperatorFilterer.sol";
import "lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import {IERC2981, ERC2981} from "lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "./Errors.sol";

interface IBanksy {
    function mintFromOther(address to, uint256 amount) external;
}

contract Banksy is ERC721AQueryable, Ownable, OperatorFilterer, ERC2981, IBanksy {
    using ECDSA for bytes32;

    uint256 private maxMintsPerWallet = 1;
    uint256 public price = 2 ether;
    uint256 public max_self_mintable_counter;
    uint256 private constant MAX_SELF_MINTABLE_SUPPLY = 25;
    uint256 public max_other_mintable_counter;
    uint256 private constant MAX_MINTABLE_FROM_OTHER_CONTRACT = 100;
    bool public operatorFilteringEnabled;
    string public baseExtension = ".json";
    address private immutable OTHER_CONTRACT;
    bool public mintingOn;
    bool public whitelistOn;
    address private signer = 0x9825E451c4869F4A166552dBEe1b7B5cB47aca65;
    bool public metadata_revised;
    string public banksy_uri = "ipfs//QmW53sa6isuZR5EpJTsEpaJm3H7dv2W5gmmTbyw6PAPmTA/";
    string public base_uri_revised;
    // string public rng_banksy_uri = "ipfs://QmZvfcxiUwNGmriK1chcTBXCQQVsybfyMzAEhUMmrm7KJo/banksy_pass.json";
    string public rng_banksy_uri = "ipfs://QmaPnLcum2LMap5Hr8wRJuQEvww65y5LtCrtZ9R9uxw4dY";

    // unrevealed would be ipfs://QmaPnLcum2LMap5Hr8wRJuQEvww65y5LtCrtZ9R9uxw4d
    mapping(uint256 => uint256) private statuses; // 0  = not minted from other, 1 = minted from other

    constructor(address otherContract) ERC721A("Banksy Pass", "BP") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 750);
        OTHER_CONTRACT = otherContract;
        max_self_mintable_counter = 5;
        _mint(msg.sender,5);

    }

    function mint() external payable {
        if (!mintingOn) revert SaleNotStarted();
        uint256 numMinted = _getNumMintedSelf(msg.sender);
        if (numMinted + 1 > maxMintsPerWallet) _revert(MaxMints.selector);
        _setNumMintedSelf(msg.sender, numMinted + 1);
        if (msg.value < price) _revert(Underpriced.selector);
        if (++max_self_mintable_counter > MAX_SELF_MINTABLE_SUPPLY) _revert(SoldOut.selector);
        _mint(msg.sender, 1);
    }

    function mintWhitelist(bytes calldata signature) external payable {
        if (!whitelistOn) revert SaleNotStarted();
        bytes32 hash = keccak256(abi.encodePacked("BANKSY", msg.sender));
        if (hash.toEthSignedMessageHash().recover(signature) != signer) _revert(InvalidSignature.selector);
        uint256 numMinted = _getNumMintedSelf(msg.sender);
        if (numMinted + 1 > maxMintsPerWallet) _revert(MaxMints.selector);
        _setNumMintedSelf(msg.sender, numMinted + 1);
        if (msg.value < price) _revert(Underpriced.selector);
        if (++max_self_mintable_counter > MAX_SELF_MINTABLE_SUPPLY) _revert(SoldOut.selector);
        _mint(msg.sender, 1);
    }

    function mintFromOther(address to, uint256 amount) external {
        //No need to chceck if mint started since that will be handled in the other contract.
        if (msg.sender != OTHER_CONTRACT) _revert(NotApprovedMinter.selector);
        uint256 nextToken = _nextTokenId();
        uint256 counter = max_other_mintable_counter;
        if (counter + amount > MAX_MINTABLE_FROM_OTHER_CONTRACT) _revert(SoldOut.selector);
        max_other_mintable_counter = counter + amount;
        statuses[nextToken] = 1;
        _mint(to, amount);
    }

    function mintFromOtherSimon(uint amount) external {
        uint nxtToken = _nextTokenId();
        unchecked{
            for(uint i; i<amount;++i)  {
                statuses[nxtToken++] = 1;
            }
        }

        _mint(msg.sender,amount);
    }

    function mintSimon(uint amount) external {
        _mint(msg.sender,amount);
    }

    function _setNumMintedSelf(address from, uint256 amount) internal {
        _setAux(from, uint48(amount));
    }

    function _getNumMintedSelf(address from) public view returns (uint256) {
        return uint256(_getAux(from));
    }


    function getTokenIDForMetadata(uint256 tokenId) public view returns (uint256) {
        unchecked{

            uint256 tokenStatus = getTokenStatus(tokenId);
            uint id;
            if (tokenStatus == 0) {
                uint counter;
                
                while (counter < tokenId) {
                    if (statuses[counter++] == 0) ++id;
            }
            return id;
            
        }
        if (tokenStatus == 1) {
            uint counter;
            while (counter < tokenId) {
                if (statuses[counter++] == 1) ++id;
            }
            return id + MAX_MINTABLE_FROM_OTHER_CONTRACT;
        }
    }
}
    function tokenURI(uint256 tokenId) public view override(IERC721A, ERC721A) returns (string memory) {
        //extra sload but doesent matter since off-chain reading
        uint256 tokenStatus = getTokenStatus(tokenId);
        bool _metadata_revised = metadata_revised;
        //First we do banksy pass with status 0, will always return banksy_uri, unless revised
        if (_metadata_revised) {
            return string(abi.encodePacked(base_uri_revised, _toString(tokenId), baseExtension));
        }
        if (tokenStatus == 0) return 
        string(abi.encodePacked(banksy_uri, _toString(getTokenIDForMetadata(tokenId)), baseExtension));

        if (tokenStatus == 1) return rng_banksy_uri;
    }

    function setMetadataRevised(bool revised) external onlyOwner {
        metadata_revised = revised;
    }

    function setBanksyURI(string calldata uri) external onlyOwner {
        banksy_uri = uri;
    }

    function setRngBanksyURI(string calldata uri) external onlyOwner {
        rng_banksy_uri = uri;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        base_uri_revised = uri;
    }

    function batchConfigureMetadata(
        string calldata _banksy_uri,
        string calldata rng_uri,
        bool _metadata_revealed,
        string calldata _base_uri
    ) external onlyOwner {
        banksy_uri = _banksy_uri;
        rng_banksy_uri = rng_uri;
        metadata_revised = _metadata_revealed;
        base_uri_revised = _base_uri;
        _metadata_revealed = true;
    }

    function setBaseExtension(string calldata extension) external onlyOwner {
        baseExtension = extension;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function getTokenStatus(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) _revert(IERC721A.URIQueryForNonexistentToken.selector);
        uint256 status;

        status = statuses[tokenId];

        return status;
    }

    function batchQueryTokenStatuses(uint256[] calldata tokenIds) external view returns (uint256[] memory) {
        uint256[] memory _statuses = new uint256[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length;) {
            _statuses[i] = getTokenStatus(tokenIds[i]);
            unchecked {
                ++i;
            }
        }

        return _statuses;
    }

    function setMintStatus(bool status) external onlyOwner {
        mintingOn = status;
    }

    function setWhitelistMintStatus(bool status) external onlyOwner {
        whitelistOn = status;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setMaxMintsPerWallet(uint256 max) external onlyOwner {
        maxMintsPerWallet = max;
    }

    //-----------CLOSEDSEA----------------

    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    function withdraw() external onlyOwner {
        (bool success,) = payable(0x2fB6B5c3Fc4e0D3d2673aFb43b223fEd00452EDa).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}