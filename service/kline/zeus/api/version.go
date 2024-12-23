//go:build !codeanalysis
// +build !codeanalysis

package api

import (
	"context"

	"github.com/NpoolPlatform/go-service-framework/pkg/logger"
	"github.com/linera-hacker/linera-dapps/service/kline/common/version"
	basetype "github.com/linera-hacker/linera-dapps/service/kline/proto/kline"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"
)

func (s *Server) Version(ctx context.Context, in *emptypb.Empty) (*basetype.VersionResponse, error) {
	resp, err := version.Version()
	if err != nil {
		logger.Sugar().Errorw("[Version] get service version error: %w", err)
		return &basetype.VersionResponse{}, status.Error(codes.Internal, "internal server error")
	}
	return resp, nil
}
