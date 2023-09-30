# TODO get some inspirations from https://build.opensuse.org/package/view_file/Virtualization:containers/helm/helm.spec?expand=1
#
# spec file for package rancher-helm
#

Name:           helm
Version:        3.12.3
Release:        3.12.3
Summary:        The Kubernetes Package Manager (Rancher's Helm fork)
License:        Apache-2.0
URL:            https://rancher-helm.run
Source0:        %{name}-%{version}.tar.xz
Source1:        vendor.tar.xz
BuildRequires:  go

%description
Helm is a tool for managing Charts. Charts are packages of pre-configured Kubernetes resources.

%prep
%setup -q
%setup -q T -D -a 1

%build
GO111MODULE=on CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags '-w -s -extldflags "-static"' \
    -mod=vendor \
    -o %{name} ./cmd/%{name}

%install
install -D -m 0755 %{name} "%{buildroot}/%{_bindir}/%{name}"

%files
%doc README.md
%license LICENSE
%{_bindir}/%{name}

%changelog

