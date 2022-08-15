pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "./interfaces/IUnicFactory.sol";
import "./interfaces/IProxyTransaction.sol";
import "./interfaces/IGetAuctionInfo.sol";
import "./interfaces/IConverter.sol";
import "./abstract/ERC20VotesUpgradeable.sol";

contract Converter is IConverter, IProxyTransaction, Initializable, ERC1155ReceiverUpgradeable, ERC20VotesUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint;

    // List of NFTs that have been deposited
    struct NFT {
    	address contractAddr;
    	uint256 tokenId;
        uint256 amount;
        uint256 triggerPrice;
    }

    mapping(uint256 => NFT) public nfts;
    // Current index and length of nfts
    uint256 public currentNFTIndex = 0;
    // If active, NFTs can’t be withdrawn
    bool public active = false;
    address public issuer;
    uint256 public cap;
    address public converterTimeLock;

    IUnicFactory public factory;

    event Deposited(uint256[] tokenIDs, uint256[] amounts, uint256[] triggerPrices, address indexed contractAddr);
    event Refunded();
    event Issued();
    event PriceUpdate(uint256[] indexed nftIndex, uint[] price);

    bytes private constant VALIDATOR = bytes('JCMY');

    function initialize (
        string memory name,
        string memory symbol,
        address _issuer,
        address _factory
    )
        public
        initializer
        returns (bool)
    {
        require(_issuer != address(0) && _factory != address(0), "Invalid address");
        __Ownable_init();
        __ERC20_init(name, symbol);
        issuer = _issuer;
        factory = IUnicFactory(_factory);
        cap = factory.uTokenSupply();
        return true;
    }

    function burn(address _account, uint256 _amount) public {
        require(msg.sender == factory.auctionHandler(), "Converter: Only auction handler can burn");
        super._burn(_account, _amount);
    }

    function setCurator(address _issuer) external {
        require(active, "Converter: Tokens have not been issued yet");
        require(msg.sender == factory.owner() || msg.sender == issuer, "Converter: Not vault manager or issuer");

        issuer = _issuer;
    }

    function setTriggers(uint256[] calldata _nftIndex, uint256[] calldata _triggerPrices) external {
        require(msg.sender == issuer, "Converter: Only issuer can set trigger prices");
        require(_nftIndex.length <= 50, "Converter: A maximum of 50 trigger prices can be set at once");
        require(_nftIndex.length == _triggerPrices.length, "Array length mismatch");
        for (uint8 i = 0; i < 50; i++) {
            if (_nftIndex.length == i) {
                break;
            }
            // require(!IGetAuctionInfo(factory.auctionHandler()).onAuction(address(this), _nftIndex[i]), "Converter: Already on auction");
            nfts[_nftIndex[i]].triggerPrice = _triggerPrices[i];
        }

        emit PriceUpdate(_nftIndex, _triggerPrices);
    }

    function setConverterTimeLock(address _converterTimeLock) public override {
        require(msg.sender == address(factory), "Converter: Only factory can set converterTimeLock");
        require(_converterTimeLock != address(0), "Invalid address");
        converterTimeLock = _converterTimeLock;
    }

    // deposits an nft using the transferFrom action of the NFT contractAddr
    function deposit(uint256[] calldata tokenIDs, uint256[] calldata amounts, uint256[] calldata triggerPrices, address contractAddr) external {
        require(msg.sender == issuer, "Converter: Only issuer can deposit");
        require(tokenIDs.length <= 50, "Converter: A maximum of 50 tokens can be deposited in one go");
        require(tokenIDs.length > 0, "Converter: You must specify at least one token ID");
        require(tokenIDs.length == triggerPrices.length, "Array length mismatch");

        if (ERC165CheckerUpgradeable.supportsInterface(contractAddr, 0xd9b67a26)){
            IERC1155Upgradeable(contractAddr).safeBatchTransferFrom(msg.sender, address(this), tokenIDs, amounts, VALIDATOR);

            for (uint8 i = 0; i < 50; i++){
                if (tokenIDs.length == i){
                    break;
                }
                nfts[currentNFTIndex++] = NFT(contractAddr, tokenIDs[i], amounts[i], triggerPrices[i]);
            }
        }
        else {
            for (uint8 i = 0; i < 50; i++){
                if (tokenIDs.length == i){
                    break;
                }
                IERC721Upgradeable(contractAddr).transferFrom(msg.sender, address(this), tokenIDs[i]);
                nfts[currentNFTIndex++] = NFT(contractAddr, tokenIDs[i], 1, triggerPrices[i]);
            }
        }

        emit Deposited(tokenIDs, amounts, triggerPrices, contractAddr);
    }

    // Function that locks NFT collateral and issues the uTokens to the issuer
    function issue() external {
        require(msg.sender == issuer, "Converter: Only issuer can issue the tokens");
        require(active == false, "Converter: Token is already active");

        active = true;
        address feeTo = factory.feeTo();
        uint256 feeAmount = 0;
        if (feeTo != address(0)) {
            feeAmount = cap.div(factory.feeDivisor());
            _mint(feeTo, feeAmount);
        }

        uint256 amount = cap - feeAmount;
        _mint(issuer, amount);

        if (!factory.airdropEnabled()) {
            emit Issued();
            return;
        }

        if (!factory.receivedAirdrop(msg.sender)) {
            bool airdropEligible = false;
            for (uint8 i = 0; i < currentNFTIndex; i++) {
                if (factory.isAirdropCollection(nfts[i].contractAddr)) {
                    airdropEligible = true;
                    break;
                }
            }
            if (airdropEligible) {
                if (IERC20Upgradeable(factory.unic()).balanceOf(address(factory)) < factory.airdropAmount()) {
                    emit Issued();
                    return;
                }
                factory.setAirdropReceived(msg.sender);
                IERC20Upgradeable(factory.unic()).transferFrom(address(factory), msg.sender, factory.airdropAmount());
            }
        }

        emit Issued();
    }

    // Function that allows NFTs to be refunded (prior to issue being called)
    function refund(address _to) external {
        require(!active, "Converter: Contract is already active - cannot refund");
        require(msg.sender == issuer, "Converter: Only issuer can refund");

        // Only transfer maximum of 50 at a time to limit gas per call
        uint8 _i = 0;
        uint256 _index = currentNFTIndex;
        bytes memory data;

        while (_index > 0 && _i < 50){
            NFT memory nft = nfts[_index - 1];

            if (ERC165CheckerUpgradeable.supportsInterface(nft.contractAddr, 0xd9b67a26)){
                IERC1155Upgradeable(nft.contractAddr).safeTransferFrom(address(this), _to, nft.tokenId, nft.amount, data);
            }
            else {
                IERC721Upgradeable(nft.contractAddr).safeTransferFrom(address(this), _to, nft.tokenId);
            }

            delete nfts[_index - 1];

            _index--;
            _i++;
        }

        currentNFTIndex = _index;

        emit Refunded();
    }

    function claimNFT(uint256 _nftIndex, address _to) external returns (bool) {
        require(msg.sender == factory.auctionHandler(), "Converter: Not auction handler");

        if (ERC165CheckerUpgradeable.supportsInterface(nfts[_nftIndex].contractAddr, 0xd9b67a26)){
            bytes memory data;
            IERC1155Upgradeable(nfts[_nftIndex].contractAddr).safeTransferFrom(address(this), _to, nfts[_nftIndex].tokenId, nfts[_nftIndex].amount, data);
        }
        else {
            IERC721Upgradeable(nfts[_nftIndex].contractAddr).safeTransferFrom(address(this), _to, nfts[_nftIndex].tokenId);
        }

        return true;
    }

    /**
     * ERC1155 Token ERC1155Receiver
     */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) override external returns(bytes4) {
        if(keccak256(_data) == keccak256(VALIDATOR)){
            return 0xf23a6e61;
        }
    }

    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) override external returns(bytes4) {
        if(keccak256(_data) == keccak256(VALIDATOR)){
            return 0xbc197c81;
        }
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        // Move voting rights
        _moveDelegates(_delegates[from], _delegates[to], amount);
    }

    /**
     * @dev implements the proxy transaction used by {ConverterTimeLock-executeTransaction}
     */
    function forwardCall(address target, uint256 value, bytes calldata callData) external override payable returns (bool success, bytes memory returnData) {
        require(target != address(factory), "Converter: No proxy transactions calling factory allowed");
        require(target != address(factory.unic()), "Converter: No proxy transactions calling unic allowed");
        require(msg.sender == converterTimeLock, "Converter: Caller is not the converterTimeLock contract");
        return target.call{value: value}(callData);
    }

    function getBlockTimestamp() internal view returns (uint) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }
}