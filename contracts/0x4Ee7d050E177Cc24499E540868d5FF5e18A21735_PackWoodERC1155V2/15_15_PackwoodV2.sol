// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "./ERC1155Upgradeable.sol";

contract PackWoodERC1155V2 is ERC1155Upgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;

    // token count
    uint256 public tokenCounter;

    // buy price for sereum
    uint256 private tokenPrice;

    // before uri
    string internal _before;

    // after uri
    string internal _after;

    // child address
    address public childAddress;

    // name
    string public name;

    // symbol
    string public symbol;

    // smart contract community address
    address public SmartContractCommunity;

    // commuity fee
    uint256 internal commuintyFee;

    // order data
    struct Order {
        uint256[3] tokenIds;
        uint256[3] random;
        bytes32 data;
        bytes32 signKey;
    }

    // airdrop order
    struct AirdropOrder {
        address user;
        uint256 tokenId;
    }

    uint256 tempValue;

    address CrossMintAddress;

    // smart contract wallet 2
    address public SmartContractCommunity2;

    // smart contract wallet 3
    address public SmartContractCommunity3;

    /**
     * @dev Emitted when user buys the sereum.
     */

    event buyTokenDetails(
        address from,
        address to,
        uint256 tokenId1,
        uint256 tokenId2,
        uint256 tokenId3,
        uint256 tokenId1Amt,
        uint256 tokenId2Amt,
        uint256 tokenId3Amt,
        uint256 price
    );

    /**
     * @dev Emitted when user buys the sereum through crossmint.
     */
    event crossmintToTokenDetails(
        address from,
        address sendTo,
        uint256 tokenId,
        uint256 tokenIdAmt,
        uint256 price
    );

    /**
     * @dev Emitted when user buys the sereums through crossmint.
     */
    event crossmintToTokenDetailsV2(
        address from,
        address sendTo,
        uint256[] tokenId,
        uint256[] tokenIdAmt,
        uint256 price
    );

    // modifier
    modifier onlyChild() {
        require(
            msg.sender == childAddress,
            "PackWoodERC1155: caller is not child address"
        );
        _;
    }

    /**
     * @dev updates the Child Address and crossmint address.
     *
     * @param _address updated child address.
     * @param _child_address child address
     *
     * Requirements:
     * - only owner can update.
     */
    function updateCrossMintAddress(address _address, address _child_address)
        external
        onlyOwner
    {
        CrossMintAddress = _address;
        childAddress = _child_address;
    }

    /**
     * @dev updates the community Fee percent.
     *
     * @param _percent updated child address.
     *
     * Requirements:
     * - only owner can update value.
     */

    function updateCommunityFee(uint256 _percent)
        external
        onlyOwner
        returns (bool)
    {
        commuintyFee = _percent;
        return true;
    }

    /**
     * @dev updates the skt community wallet Address.
     *
     *
     * Requirements:
     * - only owner can update value.
     */

    function updateSKTCommunityWallet(address _account) external onlyOwner {
        SmartContractCommunity = _account; // update commuinty wallet
    }

    /**
     * @dev updates the total price.
     *
     * @param _num updated price for each copy of token.
     *
     * Requirements:
     * - only owner can update value.
     */

    function updatePrice(uint256 _num) external onlyOwner returns (bool) {
        tokenPrice = _num;
        return true;
    }

    /**
     * @dev updates the default Token URI.
     *
     * @param before_ token uri before part.
     * @param after_ token uri after part.
     *
     * Requirements:
     * - only owner can update default URI.
     */

    function setTokenUri(string memory before_, string memory after_)
        external
        onlyOwner
        returns (bool)
    {
        _before = before_;
        _after = after_;
        return true;
    }

    /**
     * @dev Token URI.
     *
     * @param id token uri before part.
     *
     * returns:
     * - token URI.
     */

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _before,
                    StringsUpgradeable.toString(id),
                    _after
                )
            );
    }

    /**
     * @dev mints the token.
     *
     * @param _amount token uri before part.
     *
     * Requirements:
     * - only owner can mint.
     */
    function mintToken(uint256 _amount) external onlyOwner returns (uint256) {
        tokenCounter += 1;
        _mint(msg.sender, tokenCounter, _amount, "");
        return tokenCounter;
    }

    /**
     * @dev burns the token.
     *
     * @param _account token account.
     * @param _tokenId token id
     *
     * Requirements:
     * - only child contract can call it.
     */

    function burnToken(address _account, uint256 _tokenId)
        external
        onlyChild
        returns (bool)
    {
        _burn(_account, _tokenId, 1);
        return true;
    }

    /**
     * @dev buy the token amount.
     *
     * @param order order for buying token.
     * @param signature signature
     *
     * returns:
     * - bool.
     *
     * Emits a {buyTokenDetails} event.
     */

    function buyToken(Order memory order, bytes memory signature)
        external
        payable
        returns (bool)
    {
        bool status = SignatureCheckerUpgradeable.isValidSignatureNow(
            owner(),
            order.signKey,
            signature
        );
        require(status == true, "$PackWoodERC1155: cannot purchase the token");

        uint256 amount = order.random[0] + order.random[1] + order.random[2];
        require(
            tokenPrice * amount == msg.value,
            "PackWoodERC1155: Price is incorrect"
        );

        bytes32 hashT = keccak256(abi.encodePacked(amount, msg.sender));
        bytes32 hashV = keccak256(
            abi.encodePacked(
                order.tokenIds[0],
                order.tokenIds[1],
                order.tokenIds[2]
            )
        );
        bytes32 hashTo = keccak256(abi.encodePacked(hashT, hashV));

        require(hashTo == order.data, "PackWoodERC1155: data is incorrect");

        payable(SmartContractCommunity).transfer(msg.value);

        for (uint256 i = 0; i < order.tokenIds.length; i++) {
            if (order.random[i] > 0) {
                _safeTransferFrom(
                    owner(),
                    msg.sender,
                    order.tokenIds[i],
                    order.random[i],
                    ""
                );
            }
        }

        emit buyTokenDetails(
            owner(),
            msg.sender,
            order.tokenIds[0],
            order.tokenIds[1],
            order.tokenIds[2],
            order.random[0],
            order.random[1],
            order.random[2],
            msg.value
        );

        return true;
    }

    function whitelistedAirdrop(AirdropOrder[] calldata _airdrop)
        external
        onlyOwner
        returns (bool)
    {
        for (uint256 i = 0; i < _airdrop.length; i++) {
            _safeTransferFrom(
                owner(),
                _airdrop[i].user,
                _airdrop[i].tokenId,
                1,
                ""
            );
        }
        return true;
    }

    /**
     * @dev buy the token amount.
     *
     * @param to send to.
     * @param _count id
     *
     * returns:
     * - bool.
     *
     * Emits a {crossmintToTokenDetails} event.
     */

    function mintTo(
        address to,
        uint256 _count,
        uint256 _tokenId
    ) external payable returns (bool) {
        require(
            msg.sender == CrossMintAddress,
            "PackWoodERC1155: Method can be only called by Cross mint address"
        );

        require(
            tokenPrice * _count == msg.value,
            "PackWoodERC1155: Price is incorrect"
        );

        payable(SmartContractCommunity).transfer(msg.value);

        _safeTransferFrom(owner(), to, _tokenId, _count, "");

        emit crossmintToTokenDetails(owner(), to, _tokenId, _count, msg.value);

        return true;
    }

    /**
     * @dev buy the token amount.
     *
     * @param to send to
     * @param _count id
     * @param _tokenId array of Ids
     * @param _quantity quantity array for each id
     *
     * returns:
     * - bool.
     *
     * Emits a {crossmintToTokenDetails} event.
     */

    function mintToV2(
        address to,
        uint256 _count,
        uint256[] calldata _tokenId,
        uint256[] calldata _quantity
    ) external payable returns (bool) {
        require(
            msg.sender == CrossMintAddress,
            "PackWoodERC1155: Method can be only called by Cross mint address"
        );

        require(
            tokenPrice * _count == msg.value,
            "PackWoodERC1155: Price is incorrect" 
        );

        payable(SmartContractCommunity).transfer(msg.value);
        uint256 temp;

        for(uint256 i = 0; i < _tokenId.length; i++){
            _safeTransferFrom(owner(), to, _tokenId[i], _quantity[i], "");
            temp += _quantity[i];
        }

        require(
            temp == _count && _count <= 8,
            "PackWoodERC1155: Incorrect quantity supply" 
        );

        emit crossmintToTokenDetailsV2(owner(), to, _tokenId, _quantity, msg.value);

        return true;
    }

    // /**
    //  * @dev fee calaculation.
    // */
    // function feeCalulation(uint256 _totalPrice) private view returns (uint256) {
    //     uint256 fee = commuintyFee * _totalPrice; // change commuity fee
    //     uint256 fees = fee / 100;
    //     return fees;
    // }

    /**
     * @dev transfer the ethers to users.
     *
     * @param _addresses send to
     * @param _amounts id
     *
     */

    function transferEth(
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) external payable onlyOwner {
        require(_amounts.length == _addresses.length, "PackWoodERC1155: Invalid request");
        for(uint256 i = 0; i < _addresses.length; i++){
            payable(_addresses[i]).transfer(_amounts[i]);
        }
    }
}