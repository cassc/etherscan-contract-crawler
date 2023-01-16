//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "@charged-particles/erc721i/contracts/ERC721i.sol";

contract NiftyTicket is ERC721i {
    string public _baseTokenURI;
    address public factory;

    bool public initialized;

    modifier onlyFactory() {
        require(msg.sender == factory, "!factory");
        _;
    }

    constructor() ERC721i("", "", _msgSender(), 0) {}

    function initialize(
        string memory name_,
        string memory symbol_,
        address sudoPool,
        uint256 qty,
        string memory _newUri
    ) external {
        require(!initialized, "!initialized");
        initialized = true;

        factory = msg.sender;

        setName(name_);
        setSymbol(symbol_);

        _preMintReceiver = sudoPool;
        _maxSupply = qty;

        _preMint();

        _baseTokenURI = _newUri;

        _transferOwnership(tx.origin);
    }

    // from https://github.com/chiru-labs/ERC721A/issues/375
    function _setStringAtStorageSlot(string memory value, uint256 storageSlot)
        private
    {
        assembly {
            let stringLength := mload(value)

            switch gt(stringLength, 0x1F)
            case 0 {
                sstore(
                    storageSlot,
                    or(mload(add(value, 0x20)), mul(stringLength, 2))
                )
            }
            default {
                sstore(storageSlot, add(mul(stringLength, 2), 1))
                mstore(0x00, storageSlot)
                let dataSlot := keccak256(0x00, 0x20)
                for {
                    let i := 0
                } lt(mul(i, 0x20), stringLength) {
                    i := add(i, 0x01)
                } {
                    sstore(
                        add(dataSlot, i),
                        mload(add(value, mul(add(i, 1), 0x20)))
                    )
                }
            }
        }
    }

    function setName(string memory value) internal onlyFactory {
        _setStringAtStorageSlot(value, 1);
    }

    function setSymbol(string memory value) internal onlyFactory {
        _setStringAtStorageSlot(value, 2);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // only owner
    function changeURI(string memory _newUri) public onlyOwner {
        _baseTokenURI = _newUri;
    }
}