// SPDX-License-Identifier: MIT

/*

██╗     ███████╗██╗   ██╗███████╗██╗      ██████╗ █████╗ ██████╗ ██████╗ ███████╗
██║     ██╔════╝██║   ██║██╔════╝██║     ██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔════╝
██║     █████╗  ██║   ██║█████╗  ██║     ██║     ███████║██████╔╝██║  ██║███████╗
██║     ██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║     ██║     ██╔══██║██╔══██╗██║  ██║╚════██║
███████╗███████╗ ╚████╔╝ ███████╗███████╗╚██████╗██║  ██║██║  ██║██████╔╝███████║
╚══════╝╚══════╝  ╚═══╝  ╚══════╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝ v:alpha              

by: thebadcc   

An interactive and permissioned Terraforms derivative collection.

--DISCLAIMER--
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
AUTHOR(S) BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF THE USE OR INABILITY TO USE THE SOFTWARE OR FROM
OTHER DEALINGS IN THE SOFTWARE.

All rights reserved.

*/

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155Receiver.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/ERC165.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Base64.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

// interfaces

interface Iterraforms {
  
    function tokenToPlacement(uint) 
        external 
        view 
        returns (uint);

    function tokenToStatus(uint) 
        external 
        view 
        returns (uint);

    function ownerOf(uint) 
        external 
        view 
        returns (address);  
}

interface IterraformsData {

    function tokenSVG(uint, uint, uint, uint, uint[] memory) 
        external 
        view 
        returns (string memory);

    function levelAndTile(uint, uint) 
        external
        view
        returns (uint, uint);
}

/**
 * @dev Implementation of the basic standard multi-token with tokenURI modification.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract level is Context, Ownable, ERC165, IERC1155, IERC1155MetadataURI {
    
    using Address for address;
    using Strings for uint256;

    // chunks making up Terraform modifications
    struct lbry {
        string lbry;
    }

    // 32x32 terraform input 
    struct canvas {
        uint256[] canvas;
    }

    // token parameters for URI
    struct tokenParam{
        uint terraformId;
        uint level;
        uint mode;
        uint[] topLbry;
        uint[] botLbry;
        uint canvasLbry;
        uint loop;
        string title;
        string description;
        string artist;
    }

    // public lbry and canvas counts
    uint public lbrylength = 0;
    uint public canvasLength = 0;

    // mappings
    mapping(uint => lbry) private lbrys;
    mapping(uint => canvas) canvases;
    mapping(uint => tokenParam) public tokenParams;
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // external URL toggle and link 
    string public animationURL;
    bool public externalAnimation;

    // terraform contract integrations
    Iterraforms terraforms = Iterraforms(0x4E1f41613c9084FdB9E34E11fAE9412427480e56);
    IterraformsData terraformsData = IterraformsData(0xA5aFC9fE76a28fB12C60954Ed6e2e5f8ceF64Ff2);

    // public identifiers
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_, string memory _animationURL, bool _externalAnimation) {
    _name = name_;
    _symbol = symbol_;
    animationURL = _animationURL;
    externalAnimation = _externalAnimation;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // creates erc1155 token(s)
    function mintLevel(address to, uint256 id, uint256 amount, bytes memory data) public virtual onlyOwner {
        _mint(to, id, amount, data);
    }

    // destroys erc1155 token(s)
    function burnLevel(address from, uint256 id, uint256 amount) public virtual onlyOwner {
        _burn(from, id, amount);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }
    
    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    
    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    // returns canvas array
    function getCanvas(uint tokenId) public view returns (uint[] memory) {
        return (canvases[tokenId].canvas);
    }

    // returns lbry string
    function getLbry(uint tokenId) public view returns (string memory) {
        return (lbrys[tokenId].lbry);
    }

    // generates tokenURI
    function uri(uint256 tokenId) public view virtual override returns (string memory result) {
    string memory animation;
    if (externalAnimation == true) {
        animation = string(abi.encodePacked(
            animationURL,
            Strings.toString(tokenId)
        ));
    } else if (externalAnimation == false) {
        animation = string(abi.encodePacked(
            animationURL,
            tokenHTML(tokenId)
        ));
    }
    result = string(  
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        tokenParams[tokenId].title,
                        '","description":"',
                        tokenParams[tokenId].description,
                        '","artist":"',
                        tokenParams[tokenId].artist,
                        '","terraform":"',
                        Strings.toString(tokenParams[tokenId].terraformId),
                        '","level":"',
                        Strings.toString(tokenParams[tokenId].level),
                        '","animation_URL":"',
                        animation,
                        '","image": "data:image/svg+xml;base64,',
                        Base64.encode(
                        abi.encodePacked(tokenSVG(tokenId))
                        ),
                        '"}'
                    )
                )
            )
        );
    }

    // generates tokenHTML
    function tokenHTML(uint256 tokenId) public view virtual returns (string memory) {
        return string(
            abi.encodePacked(
                "<html><head><meta charset='UTF-8'><style>html,body,svg{margin:0;padding:0; height:100%;text-align:center;}</style></head><body>", 
                tokenSVG(tokenId), 
                "</body></html>"
            )
        );
    }

    // generates tokenSVG
    function tokenSVG(uint tokenId) 
        public 
        view 
        virtual
        returns (string memory) 
    {
        string memory svgSeed;
        
        svgSeed = terraformsData.tokenSVG(
                    tokenParams[tokenId].mode, 
                    terraforms.tokenToPlacement(tokenParams[tokenId].terraformId), 
                    10196, 
                    0, 
                    canvases[tokenParams[tokenId].canvasLbry].canvas
                );
        bytes memory _bytes=bytes(svgSeed);
    
           bytes memory trimmed_bytes = new bytes(_bytes.length-6);
            for (uint i=0; i < _bytes.length-6; i++) {
                trimmed_bytes[i] = _bytes[i];
            }
           return string(
                abi.encodePacked (
               trimmed_bytes,
               _topComp(tokenParams[tokenId].loop, tokenId),
               _botComp(tokenParams[tokenId].loop, tokenId),
               "</svg>"
                )
               );
    }

    // call function to "dream" any parcel with a level token
    function dreamSVG(uint tokenId, uint _terraformId) 
        public 
        view 
        virtual
        returns (string memory) 
    {
        string memory svgSeed;
        
        svgSeed = terraformsData.tokenSVG(
                   tokenParams[tokenId].mode,  
                    terraforms.tokenToPlacement(_terraformId), 
                    10196, 
                    0, 
                    canvases[tokenParams[tokenId].canvasLbry].canvas
                );
        bytes memory _bytes=bytes(svgSeed);
    
           bytes memory trimmed_bytes = new bytes(_bytes.length-6);
            for (uint i=0; i < _bytes.length-6; i++) {
                trimmed_bytes[i] = _bytes[i];
            }
           return string(
                abi.encodePacked (
               trimmed_bytes,
               _topComp(tokenParams[tokenId].loop, tokenId),
               _botComp(tokenParams[tokenId].loop, tokenId),
               "</svg>"
                )
               );
    }
  
    // permits terraform owner to alter base level parcel (must be on same level)
    function editToken(uint tokenId, uint _terraformId) public virtual {
        uint placement = terraforms.tokenToPlacement(_terraformId);
        (uint tokenLevel, ) = terraformsData.levelAndTile(placement, 10196);
        require (
            msg.sender == terraforms.ownerOf(_terraformId),
            "ERC721: caller is not terraform owner"
        );
        require (
        tokenParams[tokenId].level == tokenLevel + 1, 
        "ERC721: invalid token level"
        );
        require(
            _exists(tokenId), "ERC721: invalid token ID"
        );
        tokenParams[tokenId].terraformId = _terraformId;
    }

    // builds level token
    function create(uint256 tokenId, uint[] memory _topLbry, uint[] memory _botLbry, uint _mode, uint _canvasLbry, uint _loop, uint _terraformId, string memory _title, string memory _description, string memory _artist) public virtual onlyOwner {
        uint placement = terraforms.tokenToPlacement(_terraformId);
        (uint tokenLevel, ) = terraformsData.levelAndTile(placement, 10196);
        uint realLvl = tokenLevel + 1;
        tokenParams[tokenId] = tokenParam(_terraformId, realLvl, _mode, _topLbry, _botLbry,  _canvasLbry, _loop, _title, _description, _artist);
    }

    // adds lbry for reference
    function addLbry(string memory _script) public virtual onlyOwner{
         lbrys[lbrylength + 1] = lbry(_script); 
         lbrylength += 1;
    }
    
    // adds canvas for reference
    function addCanvas(uint[] memory _canvas) public virtual onlyOwner{
        canvases[canvasLength + 1] = canvas(_canvas);
        canvasLength += 1;
    }
    
    // Modifies tokenParams
    function updateToken(uint256 tokenId, uint[] memory _topUp, uint[] memory _botUp, uint _canvasUp, uint _loop, uint _mode) public virtual onlyOwner {
        tokenParams[tokenId].topLbry =  _topUp;
        tokenParams[tokenId].botLbry =  _botUp;
        tokenParams[tokenId].canvasLbry =  _canvasUp;
        tokenParams[tokenId].loop =  _loop;
        tokenParams[tokenId].mode =  _mode;
    }

    // updates the external URL and trigger
    function updateExternal(string memory _animationURL, bool _externalAnimation) public virtual onlyOwner {
        animationURL = _animationURL;
        externalAnimation = _externalAnimation;
        }

    // concats top svg slot
    function _topComp(uint loop, uint tokenId)
        private 
        view 
        returns (string memory)  {
        string memory result;    
        for (uint i = 0; i < loop; i++) {
            result = string(abi.encodePacked(result, lbrys[tokenParams[tokenId].topLbry[i]].lbry));
        }
        return string ( 
                result
        );
    }

    // concats second svg slot
    function _botComp(uint loop, uint tokenId)
        private 
        view 
        returns (string memory)  {
        string memory result;    
        for (uint i = 0; i < loop; i++) {
            result = string(abi.encodePacked(result, lbrys[tokenParams[tokenId].botLbry[i]].lbry));
        }
        return string ( 
                result
        );
    }

    // checks if level token exists
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenParams[tokenId].level != 0;
    }
}