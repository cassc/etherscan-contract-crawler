// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;
import "@openzeppelin/contracts/access/AccessControl.sol";
import {INTERCEPTOR_ROLE, MANAGER_ROLE} from "./Roles.sol";
uint constant BORROW_QUEUE = 0;
uint constant REPAY_QUEUE = 1;
uint constant LIQUIDATE_QUEUE = 2;
uint constant QUEUE_LEN = 3;

interface IInterceptor {
    function beforeEvent(
        uint _eventId,
        address _nftAsset,
        uint _tokenId
    ) external;

    function afterEvent(
        uint _eventId,
        address _nftAsset,
        uint _tokenId
    ) external;
}

abstract contract InterceptorManager is AccessControl {
    event UpdageInterceptor(uint256 indexed queueId, address indexed nftAsset, uint256 tokenId, address interceptor, bool add);
    event ExecuteInterceptor(uint256 indexed queueId, address indexed nftAsset, uint256 tokenId, address interceptor, bool before);

    mapping(address => mapping(uint256 => address[]))[QUEUE_LEN]
        private _interceptors;

    function addInterceptor(
        uint _queueId,
        address _nftAsset,
        uint _tokenId
    ) external onlyRole(INTERCEPTOR_ROLE) {
        require(_queueId < QUEUE_LEN, "Invalid queueId");
        address interceptor = msg.sender;
        address[] storage interceptors = _interceptors[_queueId][_nftAsset][
            _tokenId
        ];
        for (uint i = 0; i < interceptors.length; i++) {
            if (interceptors[i] == interceptor) {
                return;
            }
        }
        interceptors.push(interceptor);
        emit UpdageInterceptor(_queueId, _nftAsset, _tokenId, interceptor, true);
    }

    function deleteInterceptor(
        uint _queueId,
        address _nftAsset,
        uint _tokenId
    ) external onlyRole(INTERCEPTOR_ROLE) {
        address interceptor = msg.sender;

        address[] storage interceptors = _interceptors[_queueId][_nftAsset][
            _tokenId
        ];

        uint256 findIndex = 0;
        for (; findIndex < interceptors.length; findIndex++) {
            if (interceptors[findIndex] == interceptor) {
                break;
            }
        }

        if (findIndex != _interceptors.length) {
            _deleteInterceptor(_queueId, _nftAsset, _tokenId, findIndex);
        }
    }

    function purgeInterceptor(
        uint256 _queueId,
        address nftAsset,
        uint256[] calldata tokenIds,
        address interceptor
    ) public onlyRole(MANAGER_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            address[] storage interceptors = _interceptors[_queueId][nftAsset][
                tokenIds[i]
            ];
            for (
                uint256 findIndex = 0;
                findIndex < interceptors.length;
                findIndex++
            ) {
                if (interceptors[findIndex] == interceptor) {
                    _deleteInterceptor(
                        _queueId,
                        nftAsset,
                        tokenIds[i],
                        findIndex
                    );
                    break;
                }
            }
        }
    }

    function getInterceptors(
        uint _queueId,
        address nftAsset,
        uint256 tokenId
    ) public view returns (address[] memory) {
        return _interceptors[_queueId][nftAsset][tokenId];
    }

    function _deleteInterceptor(
        uint queueId,
        address nftAsset,
        uint256 tokenId,
        uint256 findIndex
    ) internal {
        address[] storage interceptors = _interceptors[queueId][nftAsset][
            tokenId
        ];
        address findInterceptor = interceptors[findIndex];
        uint256 lastInterceptorIndex = interceptors.length - 1;
        // When the token to delete is the last item, the swap operation is unnecessary.
        // Move the last interceptor to the slot of the to-delete interceptor
        if (findIndex < lastInterceptorIndex) {
            address lastInterceptorAddr = interceptors[lastInterceptorIndex];
            interceptors[findIndex] = lastInterceptorAddr;
        }
        interceptors.pop();
        emit UpdageInterceptor(queueId, nftAsset, tokenId, findInterceptor, false);
    }

    function executeInterceptors(
        uint queueId,
        bool before,
        address nftAsset,
        uint tokenId
    ) internal {
        address[] memory interceptors = _interceptors[queueId][nftAsset][
            tokenId
        ];
        for (uint i = 0; i < interceptors.length; i++) {
            if (before) {
                IInterceptor(interceptors[i]).beforeEvent(
                    queueId,
                    nftAsset,
                    tokenId
                );
            } else {
                IInterceptor(interceptors[i]).afterEvent(
                    queueId,
                    nftAsset,
                    tokenId
                );
            }

            emit ExecuteInterceptor(queueId, nftAsset, tokenId, interceptors[i], before);
        }
    }

    function beforeBorrow(address nftAsset, uint tokenId) internal {
        executeInterceptors(BORROW_QUEUE, true, nftAsset, tokenId);
    }

    function beforeRepay(address nftAsset, uint tokenId) internal {
        executeInterceptors(REPAY_QUEUE, true, nftAsset, tokenId);
    }

    function beforeLiquidate(address nftAsset, uint tokenId) internal {
        executeInterceptors(LIQUIDATE_QUEUE, true, nftAsset, tokenId);
    }

    function afterBorrow(address nftAsset, uint tokenId) internal {
        executeInterceptors(BORROW_QUEUE, false, nftAsset, tokenId);
    }

    function afterRepay(address nftAsset, uint tokenId) internal {
        executeInterceptors(REPAY_QUEUE, false, nftAsset, tokenId);
    }

    function afterLiquidate(address nftAsset, uint tokenId) internal {
        executeInterceptors(LIQUIDATE_QUEUE, false, nftAsset, tokenId);
    }
}